!ru:en
# NAME

Liveman::Append - добавляет секции для методов и функций из `lib/**.pm` в `lib/**.md`

# SYNOPSIS

```perl
use Liveman::Append;

my $liveman_append = Liveman::Append->new;

ref $liveman_append     # => Liveman::Append
```

# DESCRIPTION

Добавляет руководство по методам и функциям модулей (`lib/**.pm`) к их руководствам (`lib/**.md`).

1. Методы — это Perl-подпрограмма, начинающаяся с ключевого слова `sub`.
1. Особенности — это свойства экземпляров добавляемые ООП-фреймворками, такими как `Aion`, `Moose`, `Moo`, `Mo`, и начинающиеся с ключевого слова `has`.

# SUBROUTINES

## new (@params)

Конструктор.

## mkmd ($md)

Создаёт md-файл.

## appends ()

Добавляет в `lib/**.md` из `lib/**.pm` подпрограммы и особенности.

## append ($path)

Добавляет подпрограммы и функции из модуля (`$path`) в его мануал.

File lib/Alt/The/Plan.pm:
```perl
package Alt::The::Plan;

sub planner {
	my ($self) = @_;
}

# This is first!
sub miting {
	my ($self, $meet, $man, $woman) = @_;
}

sub _exquise_me {
	my ($self, $meet, $man, $woman) = @_;
}

1;
```

```perl
-e "lib/Alt/The/Plan.md" # -> undef

# Set the mocks:
*Liveman::Append::_git_user_name = sub {'Yaroslav O. Kosmina'};
*Liveman::Append::_git_user_email = sub {'dart@cpan.org'};
*Liveman::Append::_year = sub {2023};
*Liveman::Append::_license = sub {"Perl5"};
*Liveman::Append::_land = sub {"Rusland"};

my $liveman_append = Liveman::Append->new->append("lib/Alt/The/Plan.pm");
$liveman_append->{count}	# -> 1
$liveman_append->{added}	# -> 2

-e "lib/Alt/The/Plan.md" # -> 1

# And again:
$liveman_append = Liveman::Append->new->append("lib/Alt/The/Plan.pm");
$liveman_append->{count}	# -> 1
$liveman_append->{added}	# -> 0
```

File lib/Alt/The/Plan.md is:
```markdown
# NAME

Alt::The::Plan - 

# SYNOPSIS

\```perl
use Alt::The::Plan;

my $alt_the_plan = Alt::The::Plan->new;
\```

# DESCRIPTION

.

# SUBROUTINES

## planner ()

.

\```perl
my $alt_the_plan = Alt::The::Plan->new;
$alt_the_plan->planner  # -> .3
\```

## miting ($meet, $man, $woman)

This is first!

\```perl
my $alt_the_plan = Alt::The::Plan->new;
$alt_the_plan->miting($meet, $man, $woman)  # -> .3
\```

# INSTALL

For install this module in your system run next [command](https://metacpan.org/pod/App::cpm):

\```sh
sudo cpm install -gvv Alt::The::Plan
\```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Alt::The::Plan module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Liveman::Append module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
