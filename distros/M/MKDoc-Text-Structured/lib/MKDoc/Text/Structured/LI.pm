package MKDoc::Text::Structured::LI;
use base qw /MKDoc::Text::Structured::Base/;
use warnings;
use strict;


sub new
{
    my $class  = shift;
    my $line   = shift;

    my ($marker) = $line =~ /^((?:\*|\-|\d+\.)\s+)/;
    return unless ($marker);

    my $self   = $class->SUPER::new();
    $self->{indent_re} = " " x length ($marker);
    return $self;
}


sub is_ok
{
    my $self = shift;
    $self->{lines} || return 1;

    my $line = shift || '';    
    my $re   = $self->{indent_re};
    $line eq ''      and return 1;
    $line =~ /^\s+$/ and return 1;
    $line =~ /^$re/  and return 1;
    return;
}


sub process
{
    my $self  = shift;
    my @lines = @{$self->{lines}};

    my $re    = $self->{indent_re};
    for (@lines) { s/^$re// }

    my $text  = join "\n", @lines;
    $text     =~ s/^(?:\*|\-|\d+\.)(\s+)//;
    $text     = MKDoc::Text::Structured::process ($text);
    return "<li>$text</li>";
}


1;


__END__
