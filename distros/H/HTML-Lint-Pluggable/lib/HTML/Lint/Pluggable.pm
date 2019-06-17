package HTML::Lint::Pluggable;
use strict;
use warnings;

our $VERSION = '0.10';

use parent qw/ HTML::Lint /;

use Carp qw/croak/;
use Module::Load ();
use Package::Stash;

sub new {
    my $class = shift;

    my $subclass;
    do {
        $subclass = sprintf '%s::__ANON__::%x%x%x', $class, $$, 0+{}, int(rand(65535));
    } while $subclass->isa($class);

    push @{ Package::Stash->new($subclass)->get_or_add_symbol('@ISA') } => $class;

    return $subclass->SUPER::new(@_);
}

sub load_plugins {
    my $self = shift;
    while (@_) {
        my $plugin = shift;
        my $conf   = @_ > 0 && ref($_[0]) eq 'HASH' ? +shift : undef;
        $self->load_plugin($plugin, $conf);
    }
}

sub load_plugin {
    my ($self, $plugin, $conf) = @_;
    $plugin = "HTML::Lint::Pluggable::${plugin}" unless $plugin =~ s/^\+//;
    Module::Load::load($plugin);
    $plugin->init($self, $conf);
}

sub override {
    my ($self, $method, $code) = @_;
    my $class = ref($self) or croak('this method can called by instance only.');

    my $override_code = $code->($class->can($method));

    {
        no strict   'refs'; ## no critic
        no warnings 'redefine';
        *{"${class}::${method}"} = $override_code;
    }
}

1;
__END__

=head1 NAME

HTML::Lint::Pluggable - plugin system for HTML::Lint

=head1 VERSION

This document describes HTML::Lint::Pluggable version 0.10.

=head1 SYNOPSIS

    use HTML::Lint::Pluggable;

    my $lint = HTML::Lint::Pluggable->new;
    $lint->only_types( HTML::Lint::Error::STRUCTURE );
    $lint->load_plugins(qw/HTML5/);

    while ( my $line = <HTML> ) {
        $lint->parse( $line );
    }
    $lint->eof;
    # or $lint->parse_file( $filename );

    my $error_count = $lint->errors;

    foreach my $error ( $lint->errors ) {
        print $error->as_string, "\n";
    }

=head1 DESCRIPTION

HTML::Lint::Pluggable adds plugin system for L<HTML::Lint>.

=head1 WHY CREATED THIS MODULE?

L<HTML::Lint> is useful. But, L<HTML::Lint> can interpret *only* for rules of HTML4.
and, L<HTML::Lint> gives an error of "Character char should be written as entity" for such as for multi-byte characters.
However, you are often no problem if they are properly encoded.

These problems can be solved easily to facilitate the various hooks for L<HTML::Lint>.

=head1 INTERFACE

=head2 Methods

=head3 C<< $lint->load_plugin($module_name[, \%config]) >>

This method loads plugin for the instance.

$module_name: package name of the plugin. You can write it as two form like DBIx::Class:

    $lint->load_plugin("HTML5"); # => loads HTML::Lint::Pluggable::HTML5

If you want to load a plugin in your own name space, use '+' character before package name like following:

    $lint->load_plugin("+MyApp::Plugin::XHTML"); # => loads MyApp::Plugin::XHTML


=head3 C<< $lint->load_plugins($module_name[, \%config ], ...) >>

Load multiple plugins at one time.

   $lint->load_plugins(
       qw/HTML5/,
       WhiteList => +{
           rule => +{
               'attr-unknown' => sub {
                   my $param = shift;
                   if ($param->{tag} =~ /input|textarea/ && $param->{attr} eq 'istyle') {
                       return 1;
                   }
                   else {
                       return 0;
                   }
               },
           }
       }
   ); # => loads HTML::Lint::Pluggable::HTML5, HTML::Lint::Pluggable::WhiteList

this code is same as:

   $lint->load_plugin('HTML5'); # => loads HTML::Lint::Pluggable::HTML5
   $lint->load_plugin(WhiteList => +{
       rule => +{
           'attr-unknown' => sub {
               my $param = shift;
               if ($param->{tag} =~ /input|textarea/ && $param->{attr} eq 'istyle') {
                   return 1;
               }
               else {
                   return 0;
               }
           },
       }
   }); # => loads HTML::Lint::Pluggable::WhiteList

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<HTML::Lint>
L<HTML::Tidy5>

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
