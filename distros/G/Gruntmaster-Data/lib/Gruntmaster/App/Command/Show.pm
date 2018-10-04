package Gruntmaster::App::Command::Show;

use 5.014000;
use warnings;

our $VERSION = '6000.001';

use Gruntmaster::App '-command';
use Gruntmaster::Data;
use POSIX qw/strftime/;

sub usage_desc { '%c [-cjpu] show id' }

my %TABLE = (
	contests => \&show_contest,
	jobs     => \&show_job,
	problems => \&show_problem,
	users    => \&show_user,
);

sub validate_args {
	my ($self, $opt, $args) = @_;
	my @args = @$args;
	$self->usage_error('No table selected') unless $self->app->table;
	$self->usage_error('Wrong number of arguments') if @args != 1;
}

sub execute {
	my ($self, $opt, $args) = @_;
	my ($obj) = @$args;
	$TABLE{$self->app->table}->(%{db->select($self->app->table, '*', {id => $obj})->hash});
}

sub show_contest {
	my (%columns) = @_;
	$columns{$_} = strftime '%c', localtime $columns{$_} for qw/start stop/;

	print <<"END"
Name: $columns{name}
Owner: $columns{owner}
Start: $columns{start}
Stop: $columns{stop}
END
}

sub show_job {
	my (%columns) = @_;
	$columns{date} = strftime '%c', localtime $columns{date};

	no warnings 'uninitialized';
	print <<"END"
Problem: $columns{problem}
Contest: $columns{contest}
Owner: $columns{owner}
Date: $columns{date}
Private: @{[$columns{private} ? 'Yes' : 'No']}
Format: $columns{format}
Result: $columns{result} ($columns{result_text})
END
}

sub show_problem {
	my (%columns) = @_;

	no warnings 'uninitialized';
	print <<"END"
Name: $columns{name}
Author: $columns{author}
Statement written by: $columns{writer}
Owner: $columns{owner}
Level: $columns{level}
Value (points): $columns{value}
Private: @{[$columns{private} ? 'Yes' : 'No']}

Generator: $columns{generator}
Runner: $columns{runner}
Judge: $columns{judge}
Test count: $columns{testcnt}
Time limit: $columns{timeout}
Output limit (bytes): $columns{olimit}
END
}

sub show_user {
	my (%columns) = @_;
	$columns{since} = strftime '%c', localtime $columns{since};

	no warnings 'uninitialized';
	print <<"END"
Email: $columns{name} <$columns{email}>
Phone: $columns{phone}
Since: $columns{since}
Admin: @{[$columns{admin} ? 'Yes' : 'No']}
Level: $columns{level}
University: $columns{university}
Town: $columns{town}
Country: $columns{country}
END
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command::Show - display human-readable information about an object

=head1 SYNOPSIS

  gm -u show MGV
  gm -p show aplusb
  gm -c show test_ct
  gm -j show 100

=head1 DESCRIPTION

The get command takes an object ID and prints information about that
object in a human-readable format.

=head1 SEE ALSO

L<gm>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
