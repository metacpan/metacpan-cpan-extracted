package DracPerl::Models::Commands::Collection::LCD;
use XML::Rabbit::Root;

has_xpath_value 'color' => '/root/lcdColor';
has_xpath_value 'text'  => '/root/lcdText';
has_xpath_value 'blink' => '/root/lcdBlink';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::Collection::LCD - Return information about the LCD screen

=head1 ATTRIBUTES

=head2 color

The current color of the lcd screen

'1' : Blue (Default, nothing to report)
'2' : Orange (Warning)

=head2 text

What is currently being displayed on the screen

eg : '188 W'

=head2 blink

'0' : LCD is currently not blinking
'1' : LCD is blinking


=cut