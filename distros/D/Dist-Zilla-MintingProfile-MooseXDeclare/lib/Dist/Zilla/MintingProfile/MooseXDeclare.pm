package Dist::Zilla::MintingProfile::MooseXDeclare;
BEGIN {
  $Dist::Zilla::MintingProfile::MooseXDeclare::AUTHORITY = 'cpan:DBR';
}
{
  $Dist::Zilla::MintingProfile::MooseXDeclare::VERSION = '0.200';
}

# ABSTRACT: A minting profile for Modules written with MooseX::Declare

use Moose;
use namespace::autoclean;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding utf8

=head1 NAME

Dist::Zilla::MintingProfile::MooseXDeclare - A minting profile for Modules written with MooseX::Declare

=head1 VERSION

version 0.200

=head1 SYNOPSIS

     dzil new -P MooseXDeclare -p App New::App

or

     dzil new -P MooseXDeclare New::App

This is a minting profile for projects using MooseX::Declare.

It comes in two flavors: one for Apps (with more boilerplate stuff) and one for "regular" classes.

=head1 BUGS AND LIMITATIONS

Unfortunately, in the App-flavored Minting Process,
I can't get L<Dist::Zilla> to create my favorite structure
exactly as I want it, so you need to run
`mkdir -p libE<sol>NewE<sol>AppE<sol>{Command,Types}; touch $_.pm` after the `dzil new` call.

(From there copy paste stuff from libE<sol>NewE<sol>App.pm to the correct places)

Additionally, I can't get L<Dist::Zilla> to carry out the
substituion of `New::App` for `{{$name}}` in the minting process
across more that one file. Sorry about that and any inconveniences
this may cause you -- patches and hints are welcome!

=head1 AUTHOR

Daniel B <dbr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Daniel B.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
