use strict;
use warnings;
use Groonga::API::Test;

Groonga::API::init() and BAIL_OUT;

{ # version
  my $version = Groonga::API::get_version();
  ok defined $version, "API version: $version";
}

{ # command version
  my $version = Groonga::API::get_default_command_version();
  ok defined $version, "default command version: $version";

  my $rc = Groonga::API::set_default_command_version($version);
  is $rc => GRN_SUCCESS, "set default command version";
}

{ # package
  my $package = Groonga::API::get_package();
  ok defined $package, "package: $package";
}

{ # default encoding
  my $encoding = Groonga::API::get_default_encoding();
  ok defined $encoding, "default encoding: $encoding";

  my $rc = Groonga::API::set_default_encoding($encoding);
  is $rc => GRN_SUCCESS, "set default encoding";
}

if (version_ge("2.1.2")) {
  my $encoding = Groonga::API::encoding_to_string(GRN_ENC_UTF8);
  is $encoding => 'utf8', "stringify encoding";

  my $encoding_cd = Groonga::API::encoding_parse("utf8");
  is $encoding_cd => GRN_ENC_UTF8, "parse encoding";
}

{ # match escalation threshold
  my $threshold = Groonga::API::get_default_match_escalation_threshold();
  ok defined $threshold, "default match escalation threshold: $threshold";
  my $rc = Groonga::API::set_default_match_escalation_threshold($threshold);
  is $rc => GRN_SUCCESS, "set default match escalation threshold";
}

if (Groonga::API::get_major_version() > 1) { # plugins dir
  my $dir = Groonga::API::plugin_get_system_plugins_dir();
  ok defined $dir, "system plugins dir: $dir";
}

if (Groonga::API::get_major_version() > 1) { # plugin suffix
  my $suffix = Groonga::API::plugin_get_suffix();
  ok defined $suffix, "plugin suffix: $suffix";
}

if (version_ge("2.0.6")) { # log level
  my $level = Groonga::API::default_logger_get_max_level();
  ok defined $level, "default logger max level: $level";

  Groonga::API::default_logger_set_max_level($level);
}

if (version_ge("2.0.9")) { # query logger flags
  my $flags = Groonga::API::default_query_logger_get_flags();
  ok defined $flags, "default query logger flags: $flags";

  Groonga::API::default_query_logger_set_flags($flags);
}

{ # signal handlers
  my $rc = Groonga::API::set_int_handler();
  is $rc => GRN_SUCCESS, "set int handler";

  $rc = Groonga::API::set_term_handler();
  is $rc => GRN_SUCCESS, "set term handler";

  $rc = Groonga::API::set_segv_handler();
  is $rc => GRN_SUCCESS, "set segv handler";

}

Groonga::API::fin();

done_testing;
