package t::ErrorMessages;
@ISA = ("Exporter");
use strict;
use Exporter ();

sub _invalid_argument   {sprintf("Invalid argument: %s\n",@_)}
sub _required           {sprintf("Required option '%s' not found\n",@_)}
sub _switch_twice       {sprintf("Switch used twice: %s\n",@_)}
sub _switch_value       {sprintf("Switch can't take a value: %s=%s\n",@_)}
sub _counter_value      {sprintf("Counter option can't take a value: %s=%s\n",@_)}
sub _param_ambiguous    {sprintf("Ambiguous value for %s could be option: %s\n",@_)}
sub _param_invalid      {sprintf("Invalid parameter %s = %s\n",@_)}
sub _param_neg_value    {sprintf("Negated parameter option can't take a value: %s=%s\n",@_)}
sub _list_invalid       {sprintf("Invalid list option %s = %s\n",@_)}
sub _keypair_invalid    {sprintf("Invalid keypair '%s': %s => %s\n",@_)}
sub _list_ambiguous     {sprintf("Ambiguous value for %s could be option: %s\n",@_)}
sub _keypair            {sprintf("Badly formed keypair for '%s'\n",@_)}
sub _default_list       {sprintf("Default for list '%s' must be array reference\n",@_)}
sub _default_keypair    {sprintf("Default for keypair '%s' must be hash reference\n",@_)}
sub _default_invalid    {sprintf("Default '%s' = '%s' fails to validate\n",@_)}
sub _name_invalid       {sprintf("'%s' is not a valid option name/alias\n",@_)}
sub _name_not_unique    {sprintf("'%s' is not unique\n",@_)}
sub _name_conflicts     {sprintf("'%s' conflicts with other options\n",@_)}
sub _key_invalid        {sprintf("'%s' is not a valid option specification key\n",@_)}
sub _type_invalid       {sprintf("'%s' is not a valid option type\n",@_)}
sub _prereq_missing     {sprintf("Option '%s' requires option '%s'\n",@_)}
sub _unknown_prereq     {sprintf("Prerequisite '%s' for '%s' is not recognized\n",@_)}
sub _invalid_list       {sprintf("Option '%s' in %s must be scalar or array reference\n",@_)}
sub _invalid_keypair    {sprintf("Option '%s' in %s must be scalar or hash reference\n",@_)}
sub _invalid_splat_defaults {sprintf("Argument to %s must be a hash or hash reference\n",@_)}
sub _no_value           {sprintf("Option '%s' requires a value\n",@_)}

# keep this last;
for (keys %t::ErrorMessages::) {
    push @t::ErrorMessages::EXPORT, $_ if $_ =~ "^_";
}

1;
