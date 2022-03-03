#!/usr/bin/perl
# Copyright (c) 2016-2022 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use warnings;
use strict;
no strict 'subs';
no strict 'refs';
$| = 1;

my %type = ('country'  => 'Country',
            'language' => 'Language',
            'currency' => 'Currency',
            'script'   => 'Script',
            'langfam'  => 'LangFam',
            'langext'  => 'LangExt',
            'langvar'  => 'LangVar',
           );

sub init_tests {
   # $0 = "DATATYPE_FLAG_NUM.t"
   #       DATATYPE  = country, language, etc.
   #       FLAG      = func, old, oo, or some other value
   #
   # If FLAG is func, old, or oo, then:
   #     INPUTFILE is based on DATATYPE
   #     TESTTYPE is the same as FLAG
   # Otherwise
   #     INPUTFILE is FLAG
   #     TESTTYPE is oo
   #
   # Module is based on DATATYPE

   my $tmp      = $0;
   $tmp         =~ s,^.*/,,;
   $tmp         =~ s,\.t$,,;
   my($dt,$flag,$n) = split(/_/,$tmp);

   $::data_type = $dt;
   my $inp_file;
   if ($flag =~ /^(func|old|oo)$/) {
      $::test_type = $flag;
      $inp_file    = $dt;
   } else {
      $::test_type = 'oo';
      $inp_file    = $flag;
   }
   my $mod         = $type{$::data_type};

   require "vals_${inp_file}.pl";

   if ($::test_type eq 'old') {
      $::module = "Locale::$mod";
      eval("use $::module");
      my $tmp   = $::module . "::show_errors";
      &{ $tmp }(1);
   } elsif ($::test_type eq 'func') {
      $::module = "Locale::Codes::$mod";
      eval("use $::module");
      my $tmp   = $::module . "::show_errors";
      &{ $tmp }(1);
   } else {
      eval("use Locale::Codes");
      $::obj = new Locale::Codes $::data_type;
      $::obj->show_errors(1);
   }
}

sub test {
   my ($op,@test) = @_;
   my @ret;

   my $stderr = '';
   {
      local *STDERR;
      open STDERR, '>', \$stderr;
      @ret = _test($op,@test);
   }

   if ($stderr) {
      $stderr =~ s/\n.*//s;
      chomp($stderr);
      return $stderr;
   } else {
      return @ret;
   }
}

sub _test {
   my    ($op,@test) = @_;

   if ($op eq '2code') {
      my $code;
      if ($::obj) {
         $code = $::obj->name2code(@test);
      } else {
         $code = &{ "${::data_type}2code" }(@test);
      }
      return ($code ? lc($code) : $code);

   } elsif ($op eq '2name') {
      if ($::obj) {
         return $::obj->code2name(@test);
      } else {
         return &{ "code2${::data_type}" }(@test)
      }

   } elsif ($op eq '2names') {
      if ($::obj) {
         return $::obj->code2names(@test);
      } else {
         return &{ "code2${::data_type}s" }(@test)
      }

   } elsif ($op eq 'code2code') {
      my $code;
      if ($::obj) {
         $code = $::obj->code2code(@test);
      } else {
         $code = &{ "${::data_type}_code2code" }(@test);
      }
      return ($code ? lc($code) : $code);

   } elsif ($op eq 'all_codes') {
      my $n;
      if ($test[$#test] =~ /^\d+$/) {
         $n = pop(@test);
      }

      my @tmp;
      if ($::obj) {
         @tmp = $::obj->all_codes(@test);
      } else {
         @tmp = &{ "all_${::data_type}_codes" }(@test);
      }

      if ($n  &&  @tmp > $n) {
         return @tmp[0..($n-1)];
      } else {
         return @tmp;
      }

   } elsif ($op eq 'all_names') {
      my $n;
      if ($test[$#test] =~ /^\d+$/) {
         $n = pop(@test);
      }

      my @tmp;
      if ($::obj) {
         @tmp = $::obj->all_names(@test);
      } else {
         @tmp = &{ "all_${::data_type}_names" }(@test);
      }

      if ($n  &&  @tmp > $n) {
         return @tmp[0..($n-1)];
      } else {
         return @tmp;
      }

   } elsif ($op eq 'rename') {
      if ($::obj) {
         return $::obj->rename_code(@test);
      } else {
         return &{ "${::module}::rename_${::data_type}" }(@test)
      }
   } elsif ($op eq 'add') {
      if ($::obj) {
         return $::obj->add_code(@test);
      } else {
         return &{ "${::module}::add_${::data_type}" }(@test)
      }
   } elsif ($op eq 'delete') {
      if ($::obj) {
         return $::obj->delete_code(@test);
      } else {
         return &{ "${::module}::delete_${::data_type}" }(@test)
      }
   } elsif ($op eq 'add_alias') {
      if ($::obj) {
         return $::obj->add_alias(@test);
      } else {
         return &{ "${::module}::add_${::data_type}_alias" }(@test)
      }
   } elsif ($op eq 'delete_alias') {
      if ($::obj) {
         return $::obj->delete_alias(@test);
      } else {
         return &{ "${::module}::delete_${::data_type}_alias" }(@test)
      }
   } elsif ($op eq 'replace_code') {
      if ($::obj) {
         return $::obj->replace_code(@test);
      } else {
         return &{ "${::module}::rename_${::data_type}_code" }(@test)
      }
   } elsif ($op eq 'add_code_alias') {
      if ($::obj) {
         return $::obj->add_code_alias(@test);
      } else {
         return &{ "${::module}::add_${::data_type}_code_alias" }(@test)
      }
   } elsif ($op eq 'delete_code_alias') {
      if ($::obj) {
         return $::obj->delete_code_alias(@test);
      } else {
         return &{ "${::module}::delete_${::data_type}_code_alias" }(@test)
      }
   } elsif ($op eq 'codeset') {
      if ($::obj) {
         return $::obj->codeset(@test);
      } else {
         return &{ "${::module}::codeset" }(@test)
      }
   } elsif ($op eq 'type') {
      if ($::obj) {
         return $::obj->type(@test);
      } else {
         return &{ "${::module}::type" }(@test)
      }
   }
}

init_tests();
$::t->tests(func  => \&test,
            tests => $::tests);
$::t->done_testing();

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:

