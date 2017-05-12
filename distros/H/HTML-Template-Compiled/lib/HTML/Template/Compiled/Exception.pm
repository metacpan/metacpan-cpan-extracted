use strict;
use warnings;
{
package HTML::Template::Compiled::Exception;
our $VERSION = '1.003'; # VERSION
use Data::Dumper;
use Carp qw(croak carp);

use constant ATTR_TEXT   => 0;
use constant ATTR_FILE   => 1;
use constant ATTR_LINE   => 2;
use constant ATTR_PARSER => 3;
use constant ATTR_TOKENS => 4;
use constant ATTR_NEAR => 5;

use overload '""' => \&stringify;

sub new {
    my $class = shift;
    my $self = [];
    bless $self, $class;
    $self->init(@_);
    return $self;
}
sub init {
    my ($self, %args) = @_;
    $self->[ATTR_TEXT] = $args{text};
    $self->[ATTR_FILE] = $args{file};
    $self->[ATTR_LINE] = $args{line};
    $self->[ATTR_PARSER] = $args{parser};
    $self->[ATTR_TOKENS] = $args{tokens};
    $self->[ATTR_NEAR] = $args{near};
}
sub stringify {
    my ($self) = @_;
    my $text = $self->[ATTR_TEXT];
}

sub parser {
    return $_[0]->[ATTR_PARSER];
}


}
1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Exception - Exception class for HTC

=cut
