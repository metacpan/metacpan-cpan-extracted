#!/usr/bin/perl -w

require 5.000;
use ExtUtils::MakeMaker;
my @scripts = qw(ecs_chk_com ecs_pid_chk ecs_proc_meta ecs_proc_msg
                 ecs_scan_mail ecs_setup ecs_token ecstool ecs_ctl);
my @cgi_scripts = qw(ecs_status ecs_status.pl);
my @python_scripts = qw(ecs_amqp_recv.py ecs_amqp_send.py);
my @ecsmods = qw(Config FileBackedMessage LockedHash Message);
WriteMakefile(
    'NAME'		=> 'EMDIS::ECS',
    'VERSION_FROM'	=> 'lib/EMDIS/ECS.pm',

    # keywords supported since 5.005
    ($] >= 5.005 ?
      (ABSTRACT   => 'ECS - EMDIS Communication System',
       AUTHOR     => 'Joel Schneider <jschneid@nmdp.org>') : ()),

    'PREREQ_PM'		=> { # e.g., Module::Name => 1.1
        # uncertain whether these exact versions are absolutely required
        Authen::SASL::Perl => 2.14,
        CPAN::Version    => 5.4,
        Data::Dumper     => 2.101,
        Fcntl            => 1.03,
        File::Basename   => 2.6,
        File::Copy       => 2.03,
        File::Spec       => 0.82,
        File::Temp       => 0.12,
        Getopt::Long     => 2.25,
        IO::File         => 1.08,
        IO::Handle       => 1.21,
        IPC::Open2       => 1.01,
        MIME::QuotedPrint => 3.07,
        Net::POP3        => 2.16,
        Net::SMTP        => 2.13,
        SDBM_File        => 1.03,
        Text::ParseWords => 3.2,
    },

    # executable scripts
    'EXE_FILES' => [
        (map { "script/$_" } @scripts),
        (map { "script/$_" } @python_scripts),
        (map { "web_status/$_" } @cgi_scripts) ],

    # man pages for executable scripts
    'MAN1PODS' => {
        map { ("script/$_" => "\$(INST_MAN1DIR)/$_.1") } @scripts
    },

    # modules
    'PM' => {
        'lib/EMDIS/ECS.pm' => '$(INST_LIBDIR)/ECS.pm',
        map { ("lib/EMDIS/ECS/$_.pm" => "\$(INST_LIBDIR)/ECS/$_.pm"), } @ecsmods
    },

    # man pages for modules
    # (for some reason, ECS::Config manpage was omitted when not specified)
    'MAN3PODS' => {
        'lib/EMDIS/ECS.pm' => '$(INST_MAN3DIR)/EMDIS::ECS.3',
        map { ("lib/EMDIS/ECS/$_.pm" => "\$(INST_MAN3DIR)/EMDIS::ECS::$_.3") } @ecsmods
    },
);
