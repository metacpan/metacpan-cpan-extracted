package JavaScript::DataFormValidator;
use warnings;
use strict;
use base 'Exporter';
use vars (qw/@EXPORT $VERSION/);
@EXPORT = (qw/
    &js_dfv_profile
    &js_dfv_onsubmit
/);


=head1 NAME

JavaScript::DataFormValidator - JavaScript form validation from a Perl Data::FormValidator profile

=cut

$VERSION = '0.50';

=head1 SYNOPSIS

This module helps with setting up a JavaScript validation for a form using
Data.FormValidator, a JavaScript port of L<Data::FormValidator>.  A key feature
of this system is that it allows you to use the I<exact same> validation
profile for both Perl and JavaScript validation. 

You should read the docs for the JavaScript implementation for some limitations:
http://www.openjsan.org/doc/u/un/unrtst/Data/FormValidator/

Here's an example with HTML::Template syntax:

  <script type="text/javascript" src="../JSAN/Data/FormValidator.js"></script>

  <!-- tmpl_var dfv_profile -->

  <form action="/foo"  <tmpl_var js_dfv_onsubmit > >
  <!-- ... ->
  </form>

And then back in your perl code...

 use JavaScript::DataFormValidator;
 my $t = HTML::Template->new_file('foo.html');  
 $t->param(
    dfv_profile => js_dfv_profile( 'my_form' => {
            required => [qw/email first_name/],
            optional => 'last_name',
            constraints => {
                email => 'email',
            }
    }),
    js_dfv_onsubmit => js_dfv_onsubmit('my_form');
 );     

=head2 REQUIREMENTS

The Data.FormValidator JavaScript file must be copied to your
server so that you can call it. Download the latest version 
from here:
http://www.openjsan.org/doc/u/un/unrtst/Data/FormValidator/

=head2 js_dfv_profile( $profile_name => \%profile_hash );

$dfv_profile_in_js  = js_dfv_profile( $profile_name => \%profile_hash );

Takes a named Data::FormValidator profile in Perl, and returns a representation
of it in JavaScript, for use with the Data.FormValidator JavaScript module.

=cut

=head2 STATUS

Hopefully, it's done. It's very simple code. 

However, the API may break and change in the first weeks after the the release
as I get feedback. I'll plan to at least make a new release to remove this
notice once things seem stable. 

=cut 

sub js_dfv_profile {
    my ($name,$struct) = @_;   
    require Data::JavaScript::Anon;
    my $js = Data::JavaScript::Anon->var_dump($name,$struct);
    return Data::JavaScript::Anon->script_wrap($js);
}

=head2 js_dfv_onsubmit($profile_name);

 $onsubmit_code = js_dfv_onsubmit($profile_name);

Returns the Javascript snippet to put in your <form> tag to call the basic
C<check_and_report()> JavaScript validation function.

=cut

sub js_dfv_onsubmit {
    my $profile_name = shift;
    return qq{onSubmit="return Data.FormValidator.check_and_report(this, $profile_name);"};
}

# This would make things /really/ easy, but I'm
# =head2 js_dfv_functions();
# 
#  $js_code = js_dfv_functions();
# 
# Returns the library of JavaScript functions and objects, in a script block. Useful for quick
# tests. For production use, it's recommended to share this code in it's own file and reference
# it through a c<<script>> tag .

=head1 FUTURE DEVELOPMENT

This module is mostly released as a demonstration of how to integrate with the
L<Data.FormValidator> JavaScript project. For anything more complicated, it
will probably be easier to use this source code as starting point for a custom
solution.

=head1 

=head1 AUTHOR

Mark Stosberg, C<< <mark at summersault.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-javascript-formvalidator at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-DataFormValidator>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

=over 4

=item * CPAN Page

L<http://search.cpan.org/dist/JavaScript-DataFormValidator>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JavaScript-DataFormValidator>

=back

=head1 ACKNOWLEDGEMENTS

This uses L<Data::JavaScript::Anon> for the heavy lifting. 

=head1 COPYRIGHT & LICENSE

Copyright 2005 Mark Stosberg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of JavaScript::DataFormValidator
