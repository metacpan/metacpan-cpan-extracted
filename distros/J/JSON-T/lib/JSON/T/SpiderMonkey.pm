use 5.010;
use strict;
use warnings;
use utf8;

use JavaScript::SpiderMonkey ();

package JSON::T::SpiderMonkey;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.104';
our @ISA       = qw( JSON::T );

sub init
{
	my $self = shift;
	my (@args) = @_;
	
	my $JS = $self->{engine} = JavaScript::SpiderMonkey::->new();
	
	$JS->init;
	$JS->function_set("return_to_perl", sub {
		$self->_accept_return_value(@_);
	});
	$JS->function_set("print_to_perl", sub {
		print @_;
	});
	
	$self->SUPER::init(@args);
}

sub engine_eval
{
	my $self = shift;
	my ($code) = @_;
	
	return $self->{engine}->eval($code);
}

sub parameters
{
	my $self = shift;
	my (%args) = @_;
	
	for my $k (sort keys %args)
	{
		my $v = $args{$k};
		$v = $v->[1] if ref $v eq 'ARRAY';
		$self->{engine}->property_by_path($k, "$v");
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

JSON::T::SpiderMonkey - transform JSON using JsonT and SpiderMonkey (libjs)

=head1 DESCRIPTION

This module uses L<JavaScript::SpiderMonkey> to provide JavaScript support.

Implements:

=over

=item C<init>

=item C<engine_eval>

=item C<parameters>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<JSON::T>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2011, 2013-2014 Toby Inkster.

Licensed under the Lesser GPL:
L<http://creativecommons.org/licenses/LGPL/2.1/>.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
