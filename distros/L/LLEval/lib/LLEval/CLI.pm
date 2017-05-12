package LLEval::CLI;
use 5.008_001;
use Mouse;
use Mouse::Util::TypeConstraints;
use MouseX::StrictConstructor;
with 'MouseX::Getopt';

use LLEval;
my $lleval = LLEval->new();

my $LANG = enum __PACKAGE__ . '.lang' => (
    keys %{ $lleval->languages }
);

has lang => (
    traits       => ['MouseX::Getopt::Meta::Attribute::Trait'],
    cmd_aliases  => ['l', 'x'],
    is           => 'rw',
    isa          => $LANG,
    documentation=> 'Specifies the language to execute'
);

has oneliner => (
    traits       => ['MouseX::Getopt::Meta::Attribute::Trait'],
    cmd_aliases  => ['e'],
    is           => 'ro',
    isa          => 'Str',
    required     => 0,
    documentation=> 'Specifies the one-line script',
);

has list => (
    traits       => ['MouseX::Getopt::Meta::Attribute::Trait'],
    cmd_aliases  => ['q'],
    is           => 'ro',
    isa          => 'Bool',
    required     => 0,
    documentation=> 'Shows the list of supported languages (ext - command)',
);

has debug => (
    traits       => ['MouseX::Getopt::Meta::Attribute::Trait'],
    cmd_aliases  => ['d'],
    is           => 'ro',
    isa          => 'Bool',
    required     => 0,
    documentation=> 'Enables debugging mode',
);

sub run {
    my($self) = @_;

    if($self->list) {
        my $langs = $lleval->languages;
        foreach my $ext(sort keys %{$langs}) {
            printf "  %-6s - %s\n", $ext, $langs->{$ext};
        }
        return 0;
    }

    my $source = $self->oneliner;
    my @argv;
    my $ext;

    if(not defined $source) {
        (my $file, @argv) = @{$self->extra_argv};
        open my $in, '<', $file or confess("Cannot open '$file': $!");
        local $/;
        $source = <$in>;

        ($ext) = $file =~ /\. ([^.]+) \z/xms;
        if(defined $ext) {
            $LANG->assert_valid($ext);
        }
    }
    else {
        @argv = @{$self->extra_argv};
    }
    my $lang = $self->lang || $ext;

    # TODO: pass @argv to lleval
    print STDERR $lleval->pretty({ s => $source, l => $lang })
        if $self->debug;
    my $data = $lleval->call(s => $source, l => $lang);
    print STDERR $lleval->pretty($data) if $self->debug;

    print STDOUT $data->{stdout};
    print STDERR $data->{stderr};

    return $data->{status};
}

no Mouse::Util::TypeConstraints;
no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

LLEval::CLI - Perl extention to do something

=head1 VERSION

This document describes LLEval::CLI version 0.01.

=head1 SYNOPSIS

    use LLEval::CLI;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Dist::Maker::Template::Mouse>

=head1 AUTHOR

gfx E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, gfx. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
