=head1 NAME

DynGig::CLI::Range - CLI for DynGig::Range::String
( expand/serial/count )

=cut
package DynGig::CLI::Range;

use warnings;
use strict;
use Carp;

use IO::Select;
use Pod::Usage;
use Getopt::Long;

use DynGig::Range::String;
use DynGig::Util::Sysrw;
use DynGig::Util::CLI;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::Range;

 DynGig::CLI::Range->main( delimiter => "\n" );

=head1 SYNOPSIS

$exe B<--help>

[echo range .. |] $exe range ..

[echo range .. |] $exe range .. B<--count>

[echo range .. |] $exe range .. B<--expand> [B<--delimiter> token]

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} } qw( delimiter );

    my $delimiter = $option{delimiter};

    $delimiter =~ s/\n/newline/g;
    $delimiter =~ s/\t/tab/g;

    my $menu = DynGig::Util::CLI->new
    (
        'h|help',"print help menu",
        'c|count','count of elements',
        'e|expand','expand into a list',
        'delimiter=s',"[ $delimiter ]",
    );

    my %pod_param = ( -input => __FILE__, -output => \*STDERR );

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    croak "poll: $!\n" unless my $select = IO::Select->new();

    my ( $buffer, $length );

    $select->add( *STDIN );

    map { $length = DynGig::Util::Sysrw->read( $_, $buffer ) }
        $select->can_read( 0.1 );

    push @ARGV, split /\s+/, $buffer if $length;

    Pod::Usage::pod2usage( %pod_param ) unless @ARGV;

    my $range = DynGig::Range::String->new( \@ARGV );

    if ( $option{e} )
    {
        local $, = $option{delimiter};
        local $\ = "\n";

        print $range->list();
    }
    else
    {
        printf "%s\n", $option{c} ? $range->size() : $range->string();
    }
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
