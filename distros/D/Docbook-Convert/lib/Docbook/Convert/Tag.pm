#
#  This file is part of Docbook::Convert.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#
#
package Docbook::Convert::Tag;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
#use Docbook::Convert::Markdown::Util;
use Docbook::Convert::Constant;
use Data::Dumper;


#  Inherit Base functions (find_node etc.)
#
use base Docbook::Convert::Base;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.012';


#  Make synonyms
#
#&create_tag_synonym;


#  All done, init finished
#
1;


#===================================================================================================


sub command {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    return $self->_code($text);

    #return &_code();
}


sub para {

    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    $text=~s/ +/ /g;
    return $text;

}

__END__

=begin markdown

# NAME

Docbook::Convert::Tag - basic handlers for the custom converter

# DESCRIPTION

This internal class contains basic DocBook handlers shared with the custom
conversion path. It is retained for compatibility with that renderer and has no
supported application API.

# SEE ALSO

`Docbook::Convert`, `Docbook::Convert::Common`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Docbook::Convert::Tag - basic handlers for the custom converter


=head1 DESCRIPTION

This internal class contains basic DocBook handlers shared with the custom
conversion path. It is retained for compatibility with that renderer and has no
supported application API.


=head1 SEE ALSO

C<Docbook::Convert>, C<Docbook::Convert::Common>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
