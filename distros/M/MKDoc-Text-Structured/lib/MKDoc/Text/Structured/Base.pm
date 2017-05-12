package MKDoc::Text::Structured::Base;
use warnings;
use strict;

sub new
{
    my $class  = shift;
    return bless {}, $class;
}

sub add_line
{
    my $self = shift;
    $self->{lines} ||= [];
    push @{$self->{lines}}, @_;
}

1;

__END__
