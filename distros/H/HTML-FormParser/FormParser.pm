#  (C) 2002  Simon Drabble
#  sdrabble@cpan.org   03/22/02

#  $Id: FormParser.pm,v 1.2 2002/05/02 01:54:41 simon Exp $


package HTML::FormParser;

use HTML::Parser;

@ISA = qw(HTML::Parser);

use strict;

our $VERSION = 0.11;


# The tags we're interested in.
our @tag_names = qw(form input select textarea);



sub start
{
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;

	return unless grep { $_ eq lc($tag) } @tag_names;

	if (ref($self->{"${tag}_start_callback"}) eq 'CODE') {
		&{$self->{"${tag}_start_callback"}}($attr, $origtext);
	}
	if (ref($self->{"${tag}_callback"}) eq 'CODE') {
		&{$self->{"${tag}_callback"}}($attr, $origtext);
	}

}




sub end
{
	my ($self, $tag, $origtext) = @_;

	return unless grep { $_ eq lc($tag) } @tag_names;

	if (ref($self->{"${tag}_callback"}) eq 'CODE') {
		&{$self->{"${tag}_callback"}}($origtext);
	}
	if (ref($self->{"${tag}_end_callback"}) eq 'CODE') {
		&{$self->{"${tag}_end_callback"}}($origtext);
	}
}



sub parse
{
	my ($self, $data, @types) = @_;
	my %cbs = @types;

	for (@tag_names) {
		$self->{$_ . "_callback"} = $cbs{$_} if exists $cbs{$_};
		$self->{$_ . "_start_callback"} = $cbs{"start_$_"}
			if exists $cbs{"start_$_"};
		$self->{$_ . "_end_callback"} = $cbs{"end_$_"}
			if exists $cbs{"end_$_"};
	}
	$self->SUPER::parse($data);
}


1;

__END__

=head1 NAME

HTML::FormParser - Do things with the contents of HTML forms.

=head1 SYNOPSIS

  use HTML::FormParser;
  $p = HTML::FormParser->new();
  $p->parse($html, form => sub { ... }, input => sub { ... });
	

=head1 DESCRIPTION

An object-oriented module inheriting from HTML::Parser. HTML::FormParser takes
a string containing HTML text and parses it, looking for forms. 

Since this package inherits from HTML::Parser, only the API unique to
HTML::FormParser is described.

Each type of tag that might be found in a form can have three kinds of action
associated with it via callbacks. Callbacks are passed to the L<parse()|parse>
method, and take up to three forms.

  o  start_${tagname}  Called whenever $tagname is opened.
  o  ${tagname}        Called immediately after start_${tagname}, and
                       immediately before end_${tagname}.
  o  end_${tagname}    Called whenever a closing $tagname is encountered.

Each of these callbacks will be passed the attributes and original tag text as
parameters, when called.	

=head2 EXAMPLE

  use HTML::FormParser;
  $p = HTML::FormParser->new();
  $p->parse($html,
      start_form => sub {
        my ($attr, $origtext) = @_;
        print "Form action is $attr->{action}\n";
      });
  
	
=head1 METHODS

=over 4

=item start($parser, $tag, $attr, $attrseq, $origtext);

Called whenever a particular start tag has been recognised. This module
recognises these tags: <form>, <input>, <textarea> & <select>.

This method will be called by the parser and is not intended to be called from
an application. 

=item end($parser, $tag, $origtext); 

Called whenever a particular end tag is encountered.

This method will be called by the parser and is not intended to be called from
an application. 

=item $p->parse($html, tag_type => \&coderef, ...);

This method is all you really need to do. Call it with callbacks for each tag
type. These will be executed as described above.


=back

=head2 EXPORTS

Nothing.

=head2 CAVEATS, BUGS, and TODO

o  $p->parse() should ideally accept different forms for the html parameter,
for example it should read from a stream or filehandle. 


=head1 AUTHOR

Simon Drabble  E<lt>sdrabble@cpan.orgE<gt>
(C) 2002  Simon Drabble

This software is released under the same terms as perl.


=cut

