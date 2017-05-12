package MKDoc::Text::Structured::PRE;
use base qw /MKDoc::Text::Structured::Base/;
use MKDoc::Text::Structured::Inline;
use warnings;
use strict;


sub new
{
    my $class  = shift;
    my $line = shift;

    $line =~ s/^\s*$// and return;

    my ($indent) = $line =~ /^(\s+)/;
    return unless ($indent);

    my $self = $class->SUPER::new();
    $self->{indent} = $indent;
    return $self;
}


sub is_ok
{
    my $self = shift;
    my $line = shift;
    return $line =~ /^\s/;
}


sub process
{
    my $self   = shift;
    my @lines  = @{$self->{lines}};
    my $indent = $self->{indent};
    for (@lines)
    {
        my ($_indent) = $_ =~ /^(\s+)/;
        $indent = $_indent if (length ($_indent) lt length ($indent));
    }
    my $text   = join "\n", map { s/^$indent//; $_ } @lines;

    # minimal encoding since we don't want all
    # the inline fluff
    $text      =~ s/&/&amp;/g;
    $text      =~ s/</&lt;/g;
    $text      =~ s/>/&gt;/g;

    return "<pre>$text</pre>";
}


1;


__END__
