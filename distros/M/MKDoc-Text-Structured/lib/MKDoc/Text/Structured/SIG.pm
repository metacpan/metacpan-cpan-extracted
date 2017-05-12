package MKDoc::Text::Structured::SIG;
use base qw /MKDoc::Text::Structured::Base/;
use warnings;
use strict;


sub new
{
    my $class = shift;
    my $line  = shift;
    $line eq '-- ' and return $class->SUPER::new();
    return;
}


sub is_ok { return 1 };


sub process
{
    my $self   = shift;
    my @lines  = @{$self->{lines}};
    my $text   = join "\n", @lines;

    return "<pre>$text</pre>";
}


1;


__END__
