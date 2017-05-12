package Dist::Zilla::Plugin::JSAN::NPM::Publish;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::NPM::Publish::VERSION = '0.06';
}

# ABSTRACT: Publish your module in npm with `dzil release`  

use Moose;

with 'Dist::Zilla::Role::Releaser';

use Path::Class;


has 'sudo' => (
    is          => 'rw',
    
    default     => 0
);


# required by [Twitter] 

has 'user' => (
    is          => 'rw',
    default     => 'CPANID'
);


#================================================================================================================================================================================================================================================
sub release {
    my ($self, $archive) = @_;
    
    my $sudo = $self->sudo ? 'sudo' : '';
    
    $self->log(`$sudo npm publish $archive`);
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;



__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN::NPM::Publish - Publish your module in npm with `dzil release`  

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

    [JSAN::NPM::Publish]
    
    sudo = 1             ; add `sudo` to the publish call, defaults to 0

=head1 DESCRIPTION

This plugin will just call `npm publish <tarball>` during `dzil release`.

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

