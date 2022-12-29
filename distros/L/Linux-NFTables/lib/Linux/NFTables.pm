package Linux::NFTables;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Linux::NFTables - Perl interface to L<libnftables|https://netfilter.org/projects/nftables/>

=head1 SYNOPSIS

    my $nft = Linux::NFTables->new()->set_output_options('json');

    my $json = $nft->run_cmd("list tables");

=head1 DESCRIPTION

This module provides a Perl interface to
L<nftables|https://netfilter.org/projects/nftables/>.

=head1 CHARACTER_ENCODING

Strings into & out of this module are byte strings.

=cut

#----------------------------------------------------------------------

use Carp ();

use Call::Context ();
use Symbol::Get ();

use XSLoader;

our $VERSION = '0.01';
XSLoader::load( __PACKAGE__, $VERSION );

my $OUTPUT_OPT_PREFIX = '_NFT_CTX_OUTPUT_';
my $DEBUG_OPT_PREFIX = '_NFT_DEBUG_';

my $output_opts_hr;
my $debug_opts_hr;

#----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new()

Instantiates I<CLASS>.

=head2 $yn = I<OBJ>->get_dry_run()

Returns a boolean that indicates whether I<OBJ> is set to dry-run mode.

=head2 $obj = I<OBJ>->set_dry_run( [$yn] )

Sets or unsets dry-run mode in I<OBJ>. If the parameter is not given,
this defaults to B<ON>.

=head2 $output = I<OBJ>->run_cmd( $CMD )

Passes an arbitrary command string to nftables and returns its output.

=head2 @opts = I<OBJ>->get_output_options()

Returns a list of names, e.g., C<json> or C<guid>. Must be called
in list context.

Possible values are libnftables’s various C<NFT_CTX_OUTPUT_*> constants
(minus that prefix).

=cut

sub get_output_options {
    my ($self) = @_;

    $output_opts_hr ||= _assemble_const_hr($OUTPUT_OPT_PREFIX);

    my $flags = $self->_output_get_flags();

    return _flags_to_names($flags, $output_opts_hr);
}

=head2 $obj = I<OBJ>->set_output_options( @NAMES )

A setter complement to C<get_output_options()>.

=cut

sub set_output_options {
    my ($self, @opts) = @_;

    my $flags = _names_to_flags( $OUTPUT_OPT_PREFIX, @opts );

    return $self->_output_set_flags($flags);
}

=head2 @opts = I<OBJ>->get_debug_options()

Like C<get_output_options()> but for debug options.

Possible values are libnftables’s various C<NFT_DEBUG_*> constants
(minux that prefix).

=cut

sub get_debug_options {
    my ($self) = @_;

    $debug_opts_hr ||= _assemble_const_hr($DEBUG_OPT_PREFIX);

    my $flags = $self->_output_get_debug();

    return _flags_to_names($flags, $debug_opts_hr);
}

=head2 $obj = I<OBJ>->set_debug_options( @NAMES )

A setter complement to C<get_debug_options()>.

=cut

sub set_debug_options {
    my ($self, @opts) = @_;

    my $flags = _names_to_flags( $DEBUG_OPT_PREFIX, @opts );

    return $self->_output_set_debug($flags);
}

#----------------------------------------------------------------------

sub _names_to_flags {
    my ($prefix, @names) = @_;

    my $flags = 0;

    for my $opt (@names) {
        my $uc_opt = $opt;
        $uc_opt =~ tr<a-z><A-Z>;

        my $cr = __PACKAGE__->can( $prefix . $uc_opt) or do {
            Carp::croak "Unknown option: $opt";
        };

        $flags |= $cr->();
    }

    return $flags;
}

sub _flags_to_names {
    my ($flags, $opts_hr) = @_;

    Call::Context::must_be_list();

    my @names;

    for my $optname (sort keys %$opts_hr) {
        next if !($flags & $opts_hr->{$optname});
        push @names, $optname;
    }

    return @names;
}

sub _assemble_const_hr {
    my $prefix = shift;

    my %opts;

    for my $name (Symbol::Get::get_names()) {
        next if $name !~ m<\A$prefix(.+)>;

        my $optname = $1;
        $optname =~ tr<A-Z><a-z>;

        $opts{$optname} = __PACKAGE__->$name();
    }

    return \%opts;
}

1;
