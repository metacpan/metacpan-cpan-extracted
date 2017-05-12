package MKDoc::Text::Structured::Block;
use MKDoc::Text::Structured::P;
use MKDoc::Text::Structured::H1;
use MKDoc::Text::Structured::H2;
use MKDoc::Text::Structured::H3;
use base qw /MKDoc::Text::Structured::Base/;
use warnings;
use strict;


sub new
{
    my $class  = shift;
    my $line   = shift;
    return if ($line =~ /^\s*$/);
    return bless {}, $class;
}


sub is_ok
{
    my $self  = shift;
    my $line  = shift;
    my $obj  = MKDoc::Text::Structured::Factory->new ($line) || return;
    return 1 if (ref $obj eq ref $self);
    return;
}


sub process
{
    my $self  = shift;
    my @lines = @{$self->{lines}};

    # =========
    # Heading 1
    # =========
    @lines > 1          and
    $lines[0]  =~ /^==/ and
    $lines[-1] =~ /^==/ and do {
        shift (@lines);
        pop (@lines);
        $self->{lines} = \@lines;
        bless $self, 'MKDoc::Text::Structured::H1';
        return $self->process (@_);
    };

    # Heading 2
    # =========
    @lines > 1 and
    $lines[-1] =~ /^==/ and do {
        pop (@lines);
        $self->{lines} = \@lines;
        bless $self, 'MKDoc::Text::Structured::H2';
        return $self->process (@_);
    };

    # Heading 3 
    # --------- 
    @lines > 1 and
    $lines[-1] =~ /^--/ and do {
        pop (@lines);
        $self->{lines} = \@lines;
        bless $self, 'MKDoc::Text::Structured::H3';
        return $self->process (@_);
    };

    # normal, boring paragraph
    bless $self, 'MKDoc::Text::Structured::P';
    return $self->process (@_);
}


1;

__END__
