use strict; use warnings;
package Module::Install::Gloom;
our $VERSION = '0.25';

use Module::Install::Base;

use base 'Module::Install::Base';

our $AUTHOR_ONLY = 1;

sub use_gloom {
    my $self = shift;
    my $module = shift
        or die "use_gloom requires the name of a target module";

    return unless $self->is_admin;

    my $gloom_path = $self->admin->find_in_inc('Gloom') or return;
    open IN, $gloom_path or die "Can't open '$gloom_path' for input";
    my $code = do { local $/; <IN> };
    close IN;

    $code =~ s/package Gloom;/package $module;/;

    my $target = $module;
    $target =~ s/::/\//g;
    $target = "lib/$target.pm";
    open OUT, '>', $target or die "Can't open '$target' for output";
    print OUT $code;
    close OUT;
}

1;
