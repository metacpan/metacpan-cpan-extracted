
package Excel::Template::Plus;
use Moose;
use Module::Runtime ();

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

sub new {
    shift;
    my %options = @_;
    
    my $engine_class = 'Excel::Template::Plus::' . $options{engine};

    eval { Module::Runtime::use_module($engine_class) };
    if ($@) {
        confess "Could not load engine class ($engine_class) because " . $@;
    }
    
    my $template = eval { $engine_class->new(%options) };
    if ($@) {
        confess "Could not create template from engine class ($engine_class) because " . $@;
    }    
    
    return $template;
}

no Moose; 1;

__END__

=pod

=head1 NAME 

Excel::Template::Plus - An extension to the Excel::Template module

=head1 SYNOPSIS

  use Excel::Template::Plus;
  
  my $template = Excel::Template::Plus->new(
      engine   => 'TT',
      template => 'greeting.tmpl',
      config   => { INCLUDE  => [ '/templates' ] },
      params   => { greeting => 'Hello' }
  );
  
  $template->param(location => 'World');
  
  $template->write_file('greeting.xls');

=head1 DISCLAIMER

This is the very first release of this module, it is an idea that I and 
Rob Kinyon (the author of Excel::Template) had discussed many times, but 
never got around to doing. This is the first attempt at bring this to 
reality, it may change B<radically> as it evolves, so be warned.

=head1 DESCRIPTION

This module is an extension of the Excel::Template module, which allows 
the user to use various "engines" from which you can create Excel files
through Excel::Template. 

The idea is to use the existing (and very solid) excel file generation 
code in Excel::Template, but to extend its more templatey bits with more
powerful options. 

The only engine currently provided is the Template Toolkit engine, which 
replaces Excel::Template's built in template features (the LOOP, and IF
constructs) with the full power of TT. This is similar to the module 
Excel::Template::TT, but expands on that even further to try and create 
a more extensive system.

You can use this module to create Excel::Template-compatible XML files
using one of the supported engines. For example, with the TT engine you
could create a Excel::Template XML file like:

  <workbook>
    <worksheet name="[% worksheet_name %]">
     [% my_cols = get_list_of_columns %]
      <row>
     [% FOR col = my_cols %]
       <bold><cell>[% col %]</cell></bold>
     [% END %]
      </row>
     [% FOR my_row = get_list_of_objects %]
      <row>
         [% FOR col = my_cols %]
          <cell>[% my_row.$col %]</cell>
         [% END %]
      </row>
     [% END %]
    </worksheet>
  </workbook>

Your TT template thus creates a XML file suitable to handing over to
Excel::Template for processing. Excel::Template::Plus simplifies
the template-creation and handing-over process.

Future engine/plans include:

=over 4

=item Pure Perl

This would allow you to write you Excel::Template files using Perl itself
which would then output the XML for Excel::Template to consume. This would 
be modeled after the recently released L<Template::Declare> module perhaps.

=item TT Plugins/Macros/Wrappers

This is basically anything which will make the TT engine easier to write
templates for. I have experimented with some of these things, but I was not
happy with any of them enough to release them yet. 

=item HTML::Template 

Excel::Template's templating features are based on HTML::Template, but the 
HTML::Template plugins and other goodies are not compatible. This engine 
would bring those things to Excel::Template.

=back 

=head1 METHODS

=over 4

=item B<new (%options)>

This method basically serves as a factory for creating new engine instances 
(for which L<Excel::Template::Plus::TT> is the only one currently). The only 
parameter that it requires is I<engine>, all other parameters are passed 
onto the engine's constructor (see the individual docs for more details on 
what is required). 

=item B<meta>

Access to the metaclass. 

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 ACKNOWLEDGEMENTS

=over 4

=item This module came out of several discussions I had with Rob Kinyon.

=back

=head1 AUTHOR

Stevan Little E<lt>stevan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2014 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
