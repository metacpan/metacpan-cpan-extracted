# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2022,2023 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  https://github.com/eserte/Doit
#

package Doit::Ini;

use strict;
use warnings;
our $VERSION = '0.06';

use File::Temp ();

use Doit::Log;

my @try_implementations = qw(Config::IOD::INI Config::IniFiles Config::IniMan);
my %allowed_implementation = map { ($_,1) } @try_implementations;

sub new { bless {}, shift }
sub functions { qw(ini_change ini_info_as_HoH ini_set_implementation ini_adapter_class) }

sub ini_set_implementation {
    my(undef, @new_implementations) = @_;
    for my $new_implementation (@new_implementations) {
	if (!$allowed_implementation{$new_implementation}) {
	    error "The implementation '$new_implementation' is unknown";
	}
    }
    @try_implementations = @new_implementations;
}

sub ini_adapter_class {
    my(undef, %opts) = @_;
    my $fail = delete $opts{fail} || 0;
    die 'Unhandled options: ' . join(' ', %opts) if %opts;

    for my $impl (@try_implementations) {
	my $adapter_class = "Doit::Ini::$impl";
	if ($adapter_class->available) {
	    return $adapter_class;
	}
    }

    if ($fail) {
	error "No usable ini implementation found, tried: @try_implementations";
    }
    undef;
}

sub ini_change {
    my($doit, $filename, @changes) = @_;
    return 0 if !@changes;

    my $code;
    if (ref $changes[0] eq 'CODE') {
	if (@changes > 1) {
	    error "Too many arguments, only one code reference is allowed";
	}
	$code = $changes[0];
	@changes = ();
    } else {
	$code = sub {
	    my($self, @changes) = @_;
	    while(@changes) {
		my($section_key, $val) = (shift(@changes), shift(@changes));
		my($section, $key) = split /\./, $section_key;
		$self->set_value($section, $key, $val);
	    }
	};
    }

    my $use_adapter_class = $doit->ini_adapter_class(fail => 1);
    my $o = $use_adapter_class->new;
    $o->read_file($filename);
    $code->($o, @changes);
    my $new_ini = $o->dump_ini;
    return $doit->write_binary($filename, $new_ini);
}

sub ini_info_as_HoH {
    my($doit, $filename) = @_;

    my $use_adapter_class = $doit->ini_adapter_class(fail => 1);
    my $o = $use_adapter_class->new;
    $o->read_file($filename);
    $o->as_HoH;
}

{
    package
	Doit::Ini::ConfigBase;
    sub confobj { shift->{c} }
}

{
    package
	Doit::Ini::Config::IOD::INI;
    use base 'Doit::Ini::ConfigBase';
    sub available { eval { require Config::IOD::INI; 1 } }
    sub new { bless { o => Config::IOD->new }, shift }
    sub read_file {
	my($self, $filename) = @_;
	$self->{c} = $self->{o}->read_file($filename);
    }
    sub set_value {
	my($self, $section, $key, $val) = @_;
	$self->confobj->set_value($section, $key, $val);
    }
    sub dump_ini {
	my($self) = @_;
	$self->confobj->as_string;
    }
    sub as_HoH {
	my($self) = @_;
	$self->confobj->dump;
    }
}

{
    package
	Doit::Ini::Config::IniFiles;
    use base 'Doit::Ini::ConfigBase';
    sub available { eval { require Config::IniFiles; 1 } }
    sub new { bless { }, shift }
    sub read_file {
	my($self, $filename) = @_;
	$self->{c} = $self->{o} = Config::IniFiles->new(-file => $filename, -fallback => 'GLOBAL');
	$self->{o}->ReadConfig(-file => $filename);
    }
    sub set_value {
	my($self, $section, $key, $val) = @_;
	$self->confobj->setval($section, $key, $val);
    }
    sub dump_ini {
	my($self) = @_;
	my $ini;
	open my $fh, '>', \$ini or die $!;
	binmode $fh;
	$self->{o}->WriteConfig($fh);
	$ini;
    }
    sub as_HoH {
	my($self) = @_;
	my $o = $self->{o};
	my %ret;
	for my $section ($o->Sections) {
	    for my $parameter ($o->Parameters($section)) {
		$ret{$section}{$parameter} = $o->val($section, $parameter);
	    }
	}
	\%ret;
    }
}

{
    package
	Doit::Ini::Config::IniMan;
    use base 'Doit::Ini::ConfigBase';
    sub available { eval { die "NYI"; require Config::IniMan; 1 } }
}

1;

__END__
