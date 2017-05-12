package JSPL::Runtime;
use strict;
use warnings;

use Carp;

require JSPL::Context;
require JSPL::Error;
require JSPL::Function;
require JSPL::Array;
require JSPL::Controller;

our @ISA = qw(JSPL::RawRT);
our $MAXBYTES = 1024 ** 2 * 4;
our %Plugins = ();
my $Stock;

sub new {
    my $pkg = shift;
    bless JSPL::RawRT::create(shift || $MAXBYTES);
}

sub create_context {
    my $self = shift;
    my $plugin = shift;
    my $ctx = JSPL::Context->new($self, @_);
    if($plugin) {
	$Stock = $plugin;
	if(my $plug = $Plugins{$plugin}) {
	    $plug->{ctxcreate}->($ctx) if $plug->{ctxcreate};
	} else {
	    croak "No plugin '$plugin' installed\n";
	}
    }
    return $ctx;
}

my $stock_ctx;
sub JSPL::stock_context {
    my($pkg, $stock) = @_;
    my $clone;
    if(!defined $stock_ctx) {
	$stock ||= 'stock';
	eval "require JSPL::Runtime::\u$stock;"
	    or croak($@);
	my $rt = __PACKAGE__->new();
	$clone = $stock_ctx = $rt->create_context($stock);
	Scalar::Util::weaken($stock_ctx);
    } else {
	$clone = $stock_ctx;
    }
    return $clone;
}

sub _getplug {
    $Plugins{$Stock};
}

1;

__END__

=head1 NAME

JSPL::Runtime - Runs contexts

=head1 SYNOPSIS

    use JSPL;

    my $rt = JSPL::Runtime->new();
    my $ctx = $rt->create_context();

    # BTW, if you don't need the runtime, it is always easier to just:

    use JSPL;

    my $ctx = JSPL->stock_context();

=head1 DESCRIPTION

In SpiderMonkey, a I<runtime> is the data structure that holds javascript
variables, objects, script and contexts. Every application needs to have
a runtime. This class encapsulates the SpiderMonkey runtime object.

The main use of a runtime in JSPL is to create I<contexts>, i.e. L<JSPL::Context>
instances.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( [ $maxbytes] )

Creates a new C<JSPL::Runtime> object and returns it.

If the I<$maxbytes> option is given, it's taken to be the number of bytes that
can be allocated before garbage collection is run. If omitted defaults to 4MB.

=back

=head2 INSTANCE METHODS

=over 4

=item create_context ()

Creates a new C<JSPL::Context> object in the runtime. 

=back

=head2 PACKAGE VARIABLES

=over 4

=item $MAXBYTES

The default max number of bytes that can be allocated before garbage collection is run.
Used when you don't pass a I<$maxbytes> parameter to L</new>.

Useful to set the default before you call L<JSPL/stock_context>.

=back

=cut
