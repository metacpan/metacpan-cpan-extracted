package Devel::Memalyzer::Plugin;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Devel::Memalyzer::Plugin - Plugin documentation and namespace

=head1 DESCRIPTION

Plugins are modules that provide extra columns of memory usage data to
L<Devel::Memalyzer>.

=head1 METHODS

All plugins must implement the following methods:

=over4

=item $obj = $class->new()

Constructor, you can use base 'Devel::Memalyzer::Base' to get one for free.

=item %data = $obj->collect()

function that returns colum => value pairs. This is where the data is
collected.

=back

=head1 SYNOPSYS

    package Devel::Memalyzer::Plugin::MyPlugin;
    use strict;
    use warnings;

    use base 'Devel::Memalyzer::Base';

    sub collect {
        my $self = shift;
        my $value = $self->do_stuff;
        return ( rand_thing => $value, ... );
    }

    sub do_stuff {
        return rand(10)
    }

    1;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

