package ETL::Yertl::Command::yts;
our $VERSION = '0.037';
# ABSTRACT: Read/Write time series data

#pod =head1 SYNOPSIS
#pod
#pod =head1 DESCRIPTION
#pod
#pod =head1 SEE ALSO
#pod
#pod L<yts>
#pod
#pod =cut

use ETL::Yertl;
use ETL::Yertl::Util qw( load_module );
use Getopt::Long qw( GetOptionsFromArray :config pass_through );
use IO::Interactive qw( is_interactive );

sub main {
    my $class = shift;

    my %opt;
    if ( ref $_[-1] eq 'HASH' ) {
        %opt = %{ pop @_ };
    }

    my @args = @_;
    GetOptionsFromArray( \@args, \%opt,
        'start=s',
        'end=s',
        'short|s',
        'tags=s%',
    );
    #; use Data::Dumper;
    #; say Dumper \@args;
    #; say Dumper \%opt;

    my ( $db_spec, $metric ) = @args;

    die "Must give a database\n" unless $db_spec;

    my ( $db_type ) = $db_spec =~ m{^([^:]+):};

    my $db = load_module( adapter => $db_type )->new( $db_spec );

    # Write metrics
    if ( !is_interactive( \*STDIN ) ) {
        if ( $opt{short} ) {
            die "Must give a metric\n" unless $metric;
        }

        my $in_fmt = load_module( format => 'default' )->new( input => \*STDIN );
        my $count = 0;

        while ( my @docs = $in_fmt->read ) {
            for my $doc ( @docs ) {
                #; use Data::Dumper
                #; say "Got doc: " . Dumper $doc;
                if ( $opt{short} ) {
                    my @docs;
                    for my $stamp ( sort keys %$doc ) {
                        push @docs, {
                            timestamp => $stamp,
                            metric => $metric,
                            value => $doc->{ $stamp },
                            ( $opt{tags} ? ( tags => $opt{tags} ) : () ),
                        };
                    }
                    #; use Data::Dumper;
                    #; print Dumper \@docs;
                    $db->write_ts( @docs );
                    $count += @docs;
                }
                else {
                    $doc->{metric} ||= $metric;
                    $doc->{tags} ||= $opt{tags} if $opt{tags};
                    $db->write_ts( $doc );
                    $count++;
                }
            }
        }

        #; say "Wrote $count points";
    }
    # Read metrics
    else {
        die "Must give a metric\n" unless $metric;
        my $out_fmt = load_module( format => 'default' )->new;
        my @points = $db->read_ts( {
            metric => $metric,
            tags => $opt{tags},
            start => $opt{start},
            end => $opt{end},
        } );
        if ( $opt{short} ) {
            my %ts = map { $_->{timestamp} => $_->{value} } @points;
            print $out_fmt->write( \%ts );
        }
        else {
            print $out_fmt->write( $_ ) for @points;
        }
    }

    return 0;
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Command::yts - Read/Write time series data

=head1 VERSION

version 0.037

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<yts>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
