package Document::Maker::Pattern;

use strict;
use warnings;

use Moose;

with map { "Document::Maker::Role::$_" } qw/Logging/; # TODO Should be component

has pattern => (qw/is ro required 1/);
has template => (qw/is ro/);
has matcher => (qw/is ro/);

sub BUILD {
    my $self = shift;
    my $pattern = $self->pattern;

    my $template = $pattern; # $template should be of the form "-%-" or whatever
    if ($template =~ m/%\(.*\)/) {
        $template =~ s/%\((.*)\)/%/;
    }

    my $matcher = $pattern;
    if ($matcher =~ m/%\(.*\)/) {
        $matcher =~ s/%\((.*)\)/($1)/;
    }
    else {
		$matcher =~ s/\%/(.*)/;
    }
    $matcher = qr/$matcher/;

    $self->log->debug("Pattern template is: $template");
    $self->log->debug("Pattern matcher is: $matcher");

    $self->{template} = $template;
    $self->{matcher} = $matcher;

    return $self;
}

sub substitute {
    my $self = shift;
    my $nickname = shift;

    return $nickname if $nickname =~ $self->matcher;

    my $name = $self->template;
    $name =~ s/\%/$nickname/;
    return $name;
}

sub match {
    my $self = shift;
    my $name = shift;;
    my $matcher = $self->matcher;
    my ($nickname) = $name =~ $matcher;
    return $nickname;
}

sub nickname {
    my $self = shift;
    my $nickname = shift;

    return $nickname unless $nickname =~ $self->matcher;

    return $self->match($nickname);
}

1;
