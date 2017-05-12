package HTML::TreeBuilderX::ASP_NET::Roles::htmlElement;
use strict;
use warnings;

use Moose::Role;

Moose::init_meta( 'HTML::Element' );

sub BUILD {
	my $self = shift;
	
	Class::MOP::load_class('HTML::TreeBuilderX::ASP_NET');
	HTML::Element->meta->add_method('httpRequest', sub {
		my ( $self, $args ) = @_;
		HTML::TreeBuilderX::ASP_NET
			->new({ element=> $self, %{$args//{}} })
			->httpRequest
		;
	});

}

1;

__END__

=head1 NAME

HTML::TreeBuilderX::ASP_NET::Roles::htmlElement -- An easy hack for HTML::Element

=head1 DESCRPITION

A simple 15 line trait for L<HTML::TreeBuilderX::ASP_NET> with a nicer more transparent API. It adds the method C<-E<gt>httpRequest> to L<HTML::Element> objects that will return an L<HTTP::Request> that represents the state of the form. It reflects all of its arguments back to the L<HTML::TreeBuilderX::ASP_NET> constructor.

=head1 SYNOPSIS

	HTML::TreeBuilderX::ASP_NET->new_with_traits( traits => ['htmlElement'] );

	## returns a HTTP::Request for the form
	$root->look_down( '_tag' => 'a' )->httpRequest( $hashRef );

=head1 SEE ALSO

B<FOR ALL DOCS>

L<HTML::TreeBuilderX::ASP_NET>
