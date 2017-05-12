package HTML::Template::Compiled::Token;
use strict;
use warnings;
use Carp qw(croak carp);
use base qw(Exporter);
our @EXPORT_OK = qw(&NO_TAG &OPENING_TAG &CLOSING_TAG);
our %EXPORT_TAGS = (
    tagtypes => [qw(&NO_TAG &OPENING_TAG &CLOSING_TAG)],
);

our $VERSION = '1.003'; # VERSION

use constant ATTR_TEXT       => 0;
use constant ATTR_LINE       => 1;
use constant ATTR_OPEN_CLOSE => 2;
use constant ATTR_NAME       => 3;
use constant ATTR_ATTRIBUTES => 4;
use constant ATTR_FILE       => 5;
use constant ATTR_LEVEL      => 6;

use constant NO_TAG        => 0;
use constant OPENING_TAG   => 1;
use constant CLOSING_TAG   => 2;

sub new {
    my ($class, @args) = @_;
    my $self;
    if (@args == 1 and ref $args[0] eq 'ARRAY') {
        $self = $args[0];
    }
    else {
        $self = [];
    }
    bless $self, $class;
    return $self;
}

sub get_text       { $_[0]->[ATTR_TEXT] }
sub set_text       { $_[0]->[ATTR_TEXT] = $_[1] }
sub get_name       { $_[0]->[ATTR_NAME] }
sub set_name       { $_[0]->[ATTR_NAME] = $_[1] }
sub get_line       { $_[0]->[ATTR_LINE] }
sub set_line       { $_[0]->[ATTR_LINE] = $_[1] }
sub get_open_close { $_[0]->[ATTR_OPEN_CLOSE] }
sub set_open_close { $_[0]->[ATTR_OPEN_CLOSE] = $_[1] }
sub get_attributes { $_[0]->[ATTR_ATTRIBUTES] }
sub set_attributes { $_[0]->[ATTR_ATTRIBUTES] = $_[1] }
sub get_file       { $_[0]->[ATTR_FILE] }
sub set_file       { $_[0]->[ATTR_FILE]       = $_[1] }
sub get_level      { $_[0]->[ATTR_FILE] }
sub set_level      { $_[0]->[ATTR_FILE]       = $_[1] }

package HTML::Template::Compiled::Token::Text;
use Carp qw(croak carp);
use base qw(HTML::Template::Compiled::Token);

sub is_open  { 0 }
sub is_close { 0 }
sub is_tag   { 0 }

package HTML::Template::Compiled::Token::open;
use base qw(HTML::Template::Compiled::Token);
sub is_open  { 1 }
sub is_close { 0 }
sub is_tag   { 1 }

package HTML::Template::Compiled::Token::close;
use base qw(HTML::Template::Compiled::Token);
sub is_open  { 0 }
sub is_close { 1 }
sub is_tag   { 1 }

package HTML::Template::Compiled::Token::single;
use base qw(HTML::Template::Compiled::Token);
sub is_open  { 1 }
sub is_close { 0 }
sub is_tag   { 1 }

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Token - a compiled HTML template token

=cut

