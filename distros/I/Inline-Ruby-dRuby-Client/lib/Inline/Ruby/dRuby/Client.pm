package Inline::Ruby::dRuby::Client;
use warnings;
use strict;
use Inline::Ruby qw(rb_eval rb_call_instance_method rb_call_class_method);
use Carp;

our $VERSION = '0.0.2';

sub new {
    my ($class, $uri) = @_;
    croak 'require druby uri.' unless($uri);

    rb_eval <<END;
    require 'drb'
    DRb.start_service
END
    return rb_call_class_method('DRbObject', 'new_with_uri', $uri);
}

1;
__END__

=head1 NAME

Inline::Ruby::dRuby::Client - [quick use dRuby object from perl]


=head1 SYNOPSIS

    use Inline::Ruby::dRuby::Client;
    my $ruby_obj = Inline::Ruby::dRuby::Client->new('druby://localhost:10001')
    # call ruby's instance method
    $ruby_obj->ruby_method();

    use Inline::Ruby qw/rb_iter/; # use ruby's iter
    # call ruby's instance with block
    rb_iter($ruby_obj, sub { 
        my $arg = shift; 
        return $arg * $arg; 
    })->each;
    # If ruby's code..
    ruby_obj.each {|arg|
      return arg * arg
    }
    

=head1 DESCRIPTION

This module is dRuby object's delegetor.
use this module, so quick use ruby's instance.

=head1 AUTHOR

Yuichi Tateno  C<< <hotchpotch@gmail.com> >>

=head1 SEE ALSO

L<Inline::Ruby>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Yuichi Tateno C<< <hotchpotch@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

