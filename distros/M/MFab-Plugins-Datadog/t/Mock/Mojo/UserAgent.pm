package Mock::Mojo::UserAgent;

use Mojo::Util qw(monkey_patch);

our(@puts);

my(%original_functions);

sub apply {
    $original_functions{put} = \&Mojo::UserAgent::put;
    monkey_patch("Mojo::UserAgent", put => sub { push(@puts, \@_); });
}

sub reset {
    monkey_patch("Mojo::UserAgent", %original_functions);
    @puts = ();
}

1;
