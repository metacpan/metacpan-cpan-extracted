package Koha::Contrib::Tamil::Authority::LoadFileTask;
# ABSTRACT: Task loading authorities into a Koha instance
$Koha::Contrib::Tamil::Authority::LoadFileTask::VERSION = '0.050';
use Moose;

extends 'Koha::Contrib::Tamil::Authority::Task';

with 'MooseX::LogDispatch';


use 5.010;
use utf8;
use Locale::TextDomain 'Koha-Contrib-Tamil';



has file => ( is => 'rw', isa => 'Str' );

has fh => ( is => 'rw' );

has truncate => ( is => 'rw', isa => 'Bool' );

has dbh => ( is => 'rw' );

# Le chargement est-il effectivement fait ?
has doit => (is=> 'rw', isa => 'Bool', default => 0);

use Carp;
use C4::Context;
use C4::AuthoritiesMarc;
use List::Util qw( first );


has log_dispatch_conf => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    required => 1,
    default => sub {
        {
            class     => 'Log::Dispatch::Screen',
            min_level => 'notice',
            stderr    => 1,
        },
        {
            class     => 'Log::Dispatch::File',
            min_level => 'debug',
            filename  => 'koha_auth_load.log',
            binmode   => ':utf8',
            #format    => '[%p] %m at %F line %L%n',
        },
    },
);


sub run {
    my $self = shift;

    my $file = $self->file;
    open my $fh, "<:utf8", $file 
        or croak "Can't open authorities file: $file"; 
    $self->fh( $fh );

    my $dbh = C4::Context->dbh;
    $self->dbh( $dbh );

    if ( $self->truncate ) {
        $self->logger->info( __"Truncate table: auth_header\n" );
        $dbh->do( "truncate auth_header" );
    }

    $self->SUPER::run();
}


sub start_message {
    my $self = shift;
    my $test = $self->doit ? "" : __"** TEST **";
    my $file = $self->file;
    $self->logger->notice(
        __x("Load authorities into Koha from a file {test_flag}\n" .
            "  source: {source_file}\n" .
            "  target: Koha DB\n",
            test_flag => $test,
            source_file => $file) );
}


sub process {
    my $self = shift;
    my $fh = $self->fh;

    my $line = <$fh>; 
    if ( defined($line) ) {
        $self->SUPER::process();
        chop $line;
        my ($authcode, $sub) = $line =~ /(\w+)\t(.*)/;
        my (@subfields) = split /\t|\|/, $sub; 
        #print "auth_code => $sub\n";
        #print "tbl : ", @subfields, "\n";
        #print "size: ", $#subfields, "\n";
        my $authority = 
            first { $_->{authcode} eq $authcode } @{ $self->conf_authorities };
        return 1 if !$authority;
        #print "<$authcode>:", "0:",$subfields[0], " - 1:",$subfields[1], " => $tag\n";
      	if ( $#subfields > 0 ) {
            my $record = MARC::Record->new();
            my $leader = $record->leader();
            substr($leader, 5, 3) = 'naa';
            substr($leader, 9, 1) = 'a';    # encodage utf8
            $record->encoding( 'UTF-8' );
            $record->leader($leader);
            my $field = MARC::Field->new(
                $authority->{authtag}, '', '', @subfields);
            $record->append_fields($field);
            $self->logger->info( "$authcode: " . $field->as_formatted() . "\n" );
            AddAuthority($record, 0, $authcode) if $self->doit;
    	}
        return 1;
    }
    return 0;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Authority::LoadFileTask - Task loading authorities into a Koha instance

=head1 VERSION

version 0.050

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
