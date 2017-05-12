package Dist::Zilla::Plugin::CheckChangeLog;
$Dist::Zilla::Plugin::CheckChangeLog::VERSION = '0.02';

# ABSTRACT: Dist::Zilla with Changes check

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool';

has filename => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

sub setup_installer {
    my ( $self, $arg ) = @_;

    my @change_files;
    my $filename = $self->{filename};
    if ($filename) {
        my $file = $self->zilla->root->file($filename);
        die "[CheckChangeLog] $! $file\n" unless -e $file;
        push @change_files,
          Dist::Zilla::File::OnDisk->new( { name => $filename } );
    }
    else {
        # grep files to check if there is any Changes file
        my $files = $self->zilla->files->grep(
            sub {
                $_->name =~ m/Change/i
                  and $_->name ne $self->zilla->main_module->name;
            }
        );
        if ( scalar @$files ) {
            push @change_files, @$files;
        }
        else {
            die "[CheckChangeLog] No changelog file found.\n";
        }
    }

    foreach my $file (@change_files) {
        if (
            $self->check_file_for_version(
                $file->content, $self->zilla->version
            )
          )
        {
            $self->log( "[CheckChangeLog] OK with " . $file->name );
            return;
        }

        # XXX? prompt to edit?
    }

    print "[CheckChangeLog] No Change Log in "
      . join( ', ', map { $_->name } @change_files ) . "\n";
    die "[CheckChangeLog] Please edit\n";

    return;
}

sub check_file_for_version {
    my ( $self, $content, $version ) = @_;

    my @lines = split( /\n/, $content );
    foreach (@lines) {

        # no blanket lines
        next unless /\S/;

        # skip things that look like bullets
        next if /^\s+/;
        next if /^\*/;
        next if /^\-/;

        # seen it?
        return 1 if /\Q$version\E/;
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CheckChangeLog - Dist::Zilla with Changes check

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    # dist.ini
    [CheckChangeLog]
    
    # or
    [CheckChangeLog]
    filename = Changes.pod

=head1 DESCRIPTION

The code is mostly a copy-paste of L<ShipIt::Step::CheckChangeLog>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
