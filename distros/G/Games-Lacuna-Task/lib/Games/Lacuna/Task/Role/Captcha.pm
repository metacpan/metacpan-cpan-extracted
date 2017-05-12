package Games::Lacuna::Task::Role::Captcha;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use IO::Interactive qw(is_interactive);
use Term::ReadKey;
use Try::Tiny;

sub get_captcha {
    my ($self) = @_;
    
    return 0
        unless is_interactive();

    my $captcha_object = $self->build_object('Captcha');

    CAPTCHA:
    for (1..3) {
        my $captcha_data = $captcha_object->fetch();

        my $captcha_solution;
        say "Please solve the captcha image at ".$captcha_data->{url};
        while ( not defined( $captcha_solution = ReadLine(-1) ) ) {
            # no key pressed yet
        }
        
        chomp($captcha_solution);
            
        return 0
            if $captcha_solution =~ /^\s*$/;
        
        my $captcha_ok = 0;
        try {
            $self->log('debug','Solving captcha %s with %s',$captcha_object->guid,$captcha_solution);
            $captcha_object->solve($captcha_solution);
            $captcha_ok = 1;
        } catch {
            $self->log('error','Captcha solution for %s not valid',$captcha_object->guid);
            
        };
        return 1
            if $captcha_ok;
    }
    
    return 0;
}

return 1;

=encoding utf8

=head1 NAME

Games::Lacuna::Role::Captcha - Handle captchas

=head1 SYNOPSIS

This method is used by the client to fetch captchas and present them to the 
user if possible

=cut