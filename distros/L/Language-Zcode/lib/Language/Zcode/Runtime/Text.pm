package Language::Zcode::Runtime::Text;

use strict;
use warnings;

=head1 NAME

Language::Zcode::Runtime::Text

=head1 DESCRIPTION

This class handles different kinds of text: input, output, etc.

Actually, it holds a bunch of subclasses, so that a piece of text
knows what kind of text it is: text that was input with a keyboard
or a file, text that was read a line at a time vs. char by char, etc.

=cut


sub new {
    my ($class, $str) = @_;
    bless \$str, $class;
}


=head2 Language::Zcode::Runtime::Text::Output

Text that's being output

=cut

package Language::Zcode::Runtime::Text::Output;
@Language::Zcode::Runtime::Text::Output::ISA = qw(Language::Zcode::Runtime::Text);

=head2 Language::Zcode::Runtime::Text::Input

Text that was input (line or char, from a file or the screen)

=cut

package Language::Zcode::Runtime::Text::Input;
@Language::Zcode::Runtime::Text::Input::ISA = qw(Language::Zcode::Runtime::Text);

=head2 Language::Zcode::Runtime::Text::Input::Keypress

One keypress (read_char, mouse button).

=cut

package Language::Zcode::Runtime::Text::Input::Keypress;
@Language::Zcode::Runtime::Text::Input::Keypress::ISA = qw(Language::Zcode::Runtime::Text::Input);

=head2 Language::Zcode::Runtime::Text::Input::Line

One full line ('read' opcode).

=cut

package Language::Zcode::Runtime::Text::Input::Line;
@Language::Zcode::Runtime::Text::Input::Line::ISA = qw(Language::Zcode::Runtime::Text::Input);

=head2 Language::Zcode::Runtime::Text::Input::Screen

Thing read from the screen (keyboard, mouse, etc.)

=cut

package Language::Zcode::Runtime::Text::Input::Screen;
@Language::Zcode::Runtime::Text::Input::Screen::ISA = qw(Language::Zcode::Runtime::Text::Input);

=head2 Language::Zcode::Runtime::Text::Input::Screen::Line

Full line command read from the screen, not from a file

=cut

package Language::Zcode::Runtime::Text::Input::Screen::Line;
@Language::Zcode::Runtime::Text::Input::Screen::Line::ISA =
    qw(Language::Zcode::Runtime::Text::Input::Screen Language::Zcode::Runtime::Text::Input::Line);

=head2 Language::Zcode::Runtime::Text::Input::Screen::Keypress

Single key read from the screen, not from a file

=cut

package Language::Zcode::Runtime::Text::Input::Screen::Keypress;
@Language::Zcode::Runtime::Text::Input::Screen::Keypress::ISA = 
    qw(Language::Zcode::Runtime::Text::Input::Screen Language::Zcode::Runtime::Text::Input::Keypress);

###############################
    
=head2 Language::Zcode::Runtime::Text::Input::File

Thing read from a file

=cut

package Language::Zcode::Runtime::Text::Input::File;
@Language::Zcode::Runtime::Text::Input::File::ISA = qw(Language::Zcode::Runtime::Text::Input);
    
=head2 Language::Zcode::Runtime::Text::Input::File::Line

Full line command read from a file

=cut

package Language::Zcode::Runtime::Text::Input::File::Line;
@Language::Zcode::Runtime::Text::Input::File::Line::ISA = 
    qw(Language::Zcode::Runtime::Text::Input::File Language::Zcode::Runtime::Text::Input::Line);
    
=head2 Language::Zcode::Runtime::Text::Input::File::Keypress

Single key read from a file

=cut

package Language::Zcode::Runtime::Text::Input::File::Keypress;
@Language::Zcode::Runtime::Text::Input::File::Keypress::ISA =
    qw(Language::Zcode::Runtime::Text::Input::File Language::Zcode::Runtime::Text::Input::Keypress);

1; # End package Language::Zcode::Runtime::Text
