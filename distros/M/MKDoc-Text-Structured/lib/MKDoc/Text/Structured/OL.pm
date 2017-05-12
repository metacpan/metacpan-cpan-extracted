package MKDoc::Text::Structured::OL;
use base qw /MKDoc::Text::Structured::Base/;
use warnings;
use strict;
use MKDoc::Text::Structured::LI;


sub new
{
    my $class  = shift;
    my $line   = shift;

    my ($marker) = $line =~ /^(\d+\.\s+)/;
    return unless ($marker);

    my $self   = $class->SUPER::new();
    $self->{indent_re} = " " x length ($marker);
    return $self;
}


sub is_ok
{
    my $self = shift;
    $self->{lines} || return 1;

    my $line = shift;
    my $re   = $self->{indent_re};
    $line eq ''     and return 1;
    $line =~ /^\s+$/ and return 1;
    $line =~ /^$re/ and return 1;

    my ($marker) = $line =~ /^(\d+\.\s+)/;
    $marker and do {
        $self->{indent_re} = " " x length ($marker);
        return 1;
    };
    return;
}


sub process
{
    my $self  = shift;
    my @lines = @{$self->{lines}};
    my $text  = join "\n", @lines;
    $text     = $self->process_li ($text);
    return "<ol>$text</ol>";
}


sub process_li
{
    my $self    = shift;
    my $text    = shift;
    my @lines   = split /\n/, $text;
    my @result  = ();
    my $current = undef;

    while (scalar @lines)
    {
        my $line   = shift (@lines);
        $current ||= new MKDoc::Text::Structured::LI ($line);
        $current || next;

        if ($current->is_ok ($line))
        {
            $current->add_line ($line);
        }
        else
        {
            push @result, $current->process();
            unshift (@lines, $line);
            $current = undef;
        }
    }

    push @result, $current->process() if ($current);
    return join "\n", @result;
}


1;


__END__
