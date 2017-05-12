#!/usr/bin/env perl

use Dancer2;
use KavorkaX::Dancer2;

hook after
{
	$response->content( uc($response->content) );
}

prefix /:greeting
{
	GET, HEAD /:name
	{
		return "Why, $greeting there $name";
	}
}

dance;
