package Graph::Template::Base;

use strict;

BEGIN {
    use vars qw ($VERSION);

    $VERSION = 0.01;
}

use Graph::Template::Factory;

sub new
{
    my $class = shift;
                                                                                
    push @_, %{shift @_} while UNIVERSAL::isa($_[0], 'HASH');
    (@_ % 2) 
        and die "$class->new() called with odd number of option parameters\n";
                                                                                
    my %x = @_;
                                                                                
    # Do not use a hashref-slice here because of the uppercase'ing
    my $self = {};
    $self->{uc $_} = $x{$_} for keys %x;
                                                                                
    bless $self, $class;
}
                                                                                
sub isa { Graph::Template::Factory::isa(@_) }

sub calculate { ($_[1])->get(@_[0,2]) }
#{
#    my $self = shift;
#    my ($context, $attr) = @_;
#
#    return $context->get($self, $attr);
#}
                                                                                
sub enter_scope { ($_[1])->enter_scope($_[0]) }
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    return $context->enter_scope($self);
#}
                                                                                
sub exit_scope { ($_[1])->exit_scope(@_[0, 2]) }
#{
#    my $self = shift;
#    my ($context, $no_delta) = @_;
#
#    return $context->exit_scope($self, $no_delta);
#}
                                                                                
sub deltas
{
#    my $self = shift;
#    my ($context) = @_;
                                                                                
    return {};
}
                                                                                
sub resolve
{
#    my $self = shift;
#    my ($context) = @_;
                                                                                
    '';
}

sub render
{
#    my $self = shift;
#    my ($context) = @_;

    1;
}

1;
__END__
