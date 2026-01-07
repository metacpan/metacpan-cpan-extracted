package Gears::Context;
$Gears::Context::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Devel::StrictMode;

has param 'app' => (
	(STRICT ? (isa => InstanceOf ['Gears::App']) : ()),
);

