package MKDoc::Text::Structured::BQ;
use base qw /MKDoc::Text::Structured::Base/;
use warnings;
use strict;

sub new
{
    my $class  = shift;
    my $line   = shift;

    my ($marker, $space) = $line =~ /^(\>)(\s*)/;
    return unless ($marker);

    my $self = $class->SUPER::new();
    $self->{space} = $space || '';
    return $self;
}


sub is_ok
{
    my $self = shift;
    my $line = shift;
    $line =~ /^\s*$/ and return 1;
    return $line =~ /^\>/;
}


sub process
{
    my $self  = shift;
    my @lines = @{$self->{lines}};
    my $space = $self->{space};
    my $text  = join "\n", map {
        s/^\>//;
        s/^$space//;
        $_;
    } @lines;
     
    $text = MKDoc::Text::Structured::process ($text);
    return "<blockquote>$text</blockquote>";
}




1;


__END__
