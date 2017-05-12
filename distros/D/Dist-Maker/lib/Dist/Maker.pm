package Dist::Maker;
use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.10';

use Dist::Maker::Config;
use Dist::Maker::Util qw(parse_options);

sub pass_through { 1 }

sub option_spec {
    return(
        'config=s',
        'verbose=i',
    );
}

sub run {
    my $class = shift;

    my($options, @args) = $class->parse_options(@_);

    my $config = Dist::Maker::Config->new(
        verbose => $options->{verbose} // 3,
    );
    $config->config_file($options->{config}) if defined $options->{config};

    my $command = (@args && $args[0] !~ /^-/)
        ? shift(@args)
        : 'meta';

    my $subcommand = eval { $config->load_class("Command::$command") };
    if($@) {
        warn("Unknown subcommand: $command\n");
        warn($@) if $@ !~ /Can't locate/;
        $subcommand = $config->load_class("Command::meta");
    }
    my $o = $subcommand->new(config => $config);
    $o->run(@args);
    return;
}

1;
__END__

=head1 NAME

Dist::Maker - Yet another distribution maker

=head1 VERSION

This document describes Dist::Maker version 0.10.

=head1 SYNOPSIS

    use Dist::Maker;
    Dist::Maker->run(@ARGV);

    # See dim(1) for usage

=head1 DESCRIPTION

This is yet another distribution maker.

This software is an B<alpha> version. Any API will change without notice.

=head1 DEPENDENCIES

Perl 5.10.0 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Dist::Maker::Config> for configuration variables

L<Text::Xslate> to extend templates

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
