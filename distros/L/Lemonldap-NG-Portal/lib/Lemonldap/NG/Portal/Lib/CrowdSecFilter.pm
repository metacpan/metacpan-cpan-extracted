package Lemonldap::NG::Portal::Lib::CrowdSecFilter;

use strict;
use Mouse::Role;
use Regexp::Assemble;

use constant knownCat      => (qw(url));
use constant knownSuffixes => (qw(re txt));

# Initialization functions for CrowdsecFilter feature

sub initializeFilters {
    my ($self) = @_;
    my $filters = $self->parseFilters( $self->conf->{crowdsecFilters} );
    if ( $filters and %$filters ) {
        foreach my $cat ( keys %$filters ) {
            my $re = Regexp::Assemble->new;
            eval {
                $re->add( map { qr/(?i)$_/ } @{ $filters->{$cat}->{re} } )
                  if $filters->{$cat}->{re};
                $re->add( map { qr/(?i)\Q$_\E/ } @{ $filters->{$cat}->{txt} } )
                  if @{ $filters->{$cat}->{txt} };
            };
            if ($@) {
                $self->logger->error("Unable to parst category $cat: $@");
            }
            else {
                $self->filters->{$cat} = $re->re;
                $self->logger->debug("RE $cat: $re");
            }
        }
    }
}

sub parseFilters {
    my ( $self, $dirname, $res, $cat ) = @_;
    $self->logger->debug("Crowdsec filters, parsing $dirname");
    $res //= {};
    my $fh;
    unless ( opendir $fh, $dirname ) {
        $self->logger->error("Unable to read directory $dirname: $!");
        return $res;
    }
    my @files = grep /\w/, readdir $fh;
    closedir $fh;
  LOOP: foreach my $file (@files) {

        # Sub-directories fixes the category
        my $path = "$dirname/$file";
        if ( -d $path ) {
            if ($cat) {
                $self->parseFilters( $path, $res, $cat );
            }
            elsif ( my ($t) = grep { $file =~ m/^$_/ } knownCat ) {
                $self->parseFilters( $path, $res, $t );
            }
            else {
                $self->logger->error("Unknwon category for directory $path");
            }
            next LOOP;
        }
        $file =~ s/\.([^\.]+)$//;
        my $type = $1;
        unless ( $type and grep { $_ eq $type } knownSuffixes ) {
            $self->logger->error("Bad suffix for $path, skipping");
            next LOOP;
        }
        my $lcat = $cat;
        unless ($lcat) {
            $file =~ s/\.([^\.]+)$//;
            $lcat = $1;
            unless ($lcat) {
                $self->logger->error("Malformed file $path (missing category)");
                next LOOP;
            }
            unless ( grep { $_ eq $lcat } knownCat ) {
                $self->logger->error("Unknown category $lcat for $path");
                next LOOP;
            }
        }
        unless ( open $fh, '<', $path ) {
            $self->logger->error("Unable to read file $path: $!");
            next LOOP;
        }
        $self->logger->debug(
"Crowdsec filters, adding content of $path into category $lcat, type $type"
        );
        my $c = 0;
        foreach (<$fh>) {
            next if /^\s*#/;
            next unless /\w/;
            s/[\r\n]//g;
            push @{ $res->{$lcat}->{$type} }, $_;
            $c++;
        }
        $self->logger->debug("  -> $c lines added");
    }
    return $res;
}

1;
