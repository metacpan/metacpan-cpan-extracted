requires "autobox"                  => "0";
requires "Carp"                     => "0";
requires "Exporter"                 => "0";
requires "overload"                 => "0";
requires "parent"                   => "0";
requires "strictures"               => "2";

requires "Scalar::Util"             => "0";
requires "List::Util"               => "1.33";

requires "Class::Method::Modifiers" => "0";
requires "Module::Runtime"          => "0.013";
requires "Role::Tiny"               => "1.003";

requires "Type::Tie"                => "0.004";
recommends "Type::Tiny"             => "0.022";

requires "List::UtilsBy"            => "0.09";
recommends "List::UtilsBy::XS"      => "0.03";

on 'test' => sub {
  requires "Test::More" => "0.88";

  recommends "JSON::PP" => "0";
  recommends "Test::Without::Module" => "0";
};

on 'develop' => sub {
  recommends "Text::ZPL" => "0";
};
