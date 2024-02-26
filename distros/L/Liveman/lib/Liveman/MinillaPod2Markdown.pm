package Liveman::MinillaPod2Markdown;
# Обманка для Minilla, чтобы скопировать Module в README.md

use parent qw/Pod::Markdown/;

use File::Slurper qw/read_text write_text/;

sub new { bless {}, __PACKAGE__ }

sub parse_from_file {
    my ($self, $path) = @_;
    $self->{pm_path} = $path;
    $self->{path} = $path =~ s!\.pm$!.md!r;
    $self
}

sub as_markdown {
    my ($self) = @_;

    my $md = read_text $self->{path};
    my $pm = read_text $self->{pm_path};

    my $v = uc "version";
    my ($md_version) = $md =~ /^#[ \t]+$v\s+([\w.-]{1,32})\s/m;
    my ($pm_version) = $pm =~ /^our\s+\$$v\s*=\s*["']?([\w.-]{1,32})/m;
    my ($hd_version) = $pm =~ /^=head1[ \t]+VERSION\s+([\w.-]{1,32})\s/m;

    if(defined $pm_version and defined $md_version and $pm_version ne $md_version) {
        $md =~ s/(#[ \t]+$v\s+)[\w.-]{1,32}(\s)/$1$pm_version$2/;
        write_text $self->{path}, $md;
    }

    if(defined $pm_version and defined $hd_version and $pm_version ne $hd_version) {
        $pm =~ s/^(=head1[ \t]+VERSION\s+)[\w.-]{1,32}(\s)/$1$pm_version$2/m;
        write_text $self->{pm_path}, $pm;
    }

    $md =~ s/^!\w+:\w+\s+//;

    $md
}

1;

__END__

=encoding utf-8

=head1 NAME

Liveman::MinillaPod2Markdown – a stub for Minilla that redirects lib/MainModule.md to README.md

=head1 SYNOPSIS

	use Liveman::MinillaPod2Markdown;
	
	my $mark = Liveman::MinillaPod2Markdown->new;
	
	$mark->isa("Pod::Markdown")  # -> 1
	
	use File::Slurper qw/write_text/;
	write_text "X.md", "hi!";
	write_text "X.pm", "our \$VERSION = 1.0;";
	
	$mark->parse_from_file("X.pm");
	$mark->{path}  # => X.md
	
	$mark->as_markdown  # => hi!

=head1 DESCRIPTION

Add the line C<markdown_maker = "Liveman::MinillaPod2Markdown"> to C<minil.toml>, and Minilla will not create C<README.md> from the pod documentation of the main module, but will take it from the file of the same name next to the C<*.md> extension.

=head1 SUBROUTINES

=head2 as_markdown ()

Stub.

=head2 new ()

Constructor.

=head2 parse_from_file ($path)

Stub.

=head1 INSTALL

To install this module on your system, follow these steps LL<https://metacpan.org/pod/App::cpm>:

	sudo cpm install -gvv Liveman::MinillaPod2Markdown

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Liveman::MinillaPod2Markdown module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
