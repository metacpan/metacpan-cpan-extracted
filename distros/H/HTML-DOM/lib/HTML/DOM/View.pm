package HTML::DOM::View;

use warnings;
use strict;

use Scalar::Util qw'weaken';
use HTML::DOM::_FieldHash;

fieldhashes \my %doc;

our $VERSION = '0.058';

# -------- DOM ATTRIBUTES -------- #

sub document {
	my $old = $doc{my $self = shift};
	$doc{$self} = shift if @_;
	defined $old ? $old :();
}

sub getComputedStyle {
	my($view, $elem, $pseudo) = @_;
	my($ua,$u) = map eval{$view->${\"u$_\_style_sheet"}}, 'a','ser';
	my $doc = $view->document;

	require CSS::DOM; CSS::DOM->VERSION(.06);
	return CSS::DOM'compute_style(
		#medium => ...	
		#height => $view->innerHeight;
		#width => $view->innerWidth;
		#ppi => ...
		ua_sheet   => $ua,
		user_sheet => $u ,
		defined $doc ?
		    (author_sheets => scalar $doc->styleSheets ) : (),
		element => $elem,
		pseudo  => $pseudo,
	);
}



1

__END__

=head1 NAME

HTML::DOM::View - A Perl class for representing an HTML Document's 'defaultView'

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $view = new MyView;
  
  $doc->defaultView($view);
  
  
  package MyView;
  BEGIN { @ISA = 'HTML::DOM::View'; }
  use HTML::DOM::View;

  sub new {
      my $self = bless {}, shift; # doesn't have to be a hash
      my $doc = shift;
      $self->document($doc);
      return $self
  }

  # ...

=head1 DESCRIPTION

This class is used for an HTML::DOM object's 'default view.' It implements 
the AbstractView DOM interface.

It is an inside-out class, so you can subclass it without being constrained
to any particular object structure.

=head1 METHODS

=head2 Methods that HTML::DOM::View itself implements

=over

=item $view->document

Returns the document associated with the view.

You may pass an argument to set it, in which case the old value is 
returned. This attribute holds a weak reference to the object.

=item $view->getComputedStyle( $elem )

=item $view->getComputedStyle( $elem, $pseudo_elem )

Returns the computed style as a L<CSS::DOM::Style> object. C<$pseudo_elem>
is the name of the pseudo-element, with or without the initial colons
(1 or 2).

=back

=head2 Subclass methods that HTML::DOM::View uses

=over

=item $view->ua_style_sheet( $string )

=item $view->user_style_sheet( $string )

These are called by C<getComputedStyle> and are expected to return the user
agent and user style sheets, respectively, as L<CSS::DOM> objects.

=back

=head1 SEE ALSO

L<HTML::DOM>

