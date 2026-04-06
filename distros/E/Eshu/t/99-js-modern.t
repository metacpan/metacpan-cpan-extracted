use strict;
use warnings;
use Test::More;
use Eshu;

# Generator function
{
	my $input = <<'END';
function* range(start, end) {
for (let i = start; i <= end; i++) {
yield i;
}
}
END

	my $expected = <<'END';
function* range(start, end) {
	for (let i = start; i <= end; i++) {
		yield i;
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'generator function with yield');
}

# Optional chaining and nullish coalescing
{
	my $input = <<'END';
function getDisplayName(user) {
const name = user?.profile?.displayName ?? user?.name ?? 'Anonymous';
const email = user?.contact?.email ?? '';
return { name, email };
}
END

	my $expected = <<'END';
function getDisplayName(user) {
	const name = user?.profile?.displayName ?? user?.name ?? 'Anonymous';
	const email = user?.contact?.email ?? '';
	return { name, email };
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'optional chaining and nullish coalescing');
}

# Spread operator in object and array
{
	my $input = <<'END';
function merge(defaults, overrides) {
return {
...defaults,
...overrides,
timestamp: Date.now(),
};
}

function concat(a, b) {
return [...a, ...b];
}
END

	my $expected = <<'END';
function merge(defaults, overrides) {
	return {
		...defaults,
		...overrides,
		timestamp: Date.now(),
	};
}

function concat(a, b) {
	return [...a, ...b];
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'spread operator in object and array literals');
}

# Destructuring with rename and defaults
{
	my $input = <<'END';
function processUser(data) {
const {
id: userId,
name: userName,
role = 'user',
} = data;
return { userId, userName, role };
}
END

	my $expected = <<'END';
function processUser(data) {
	const {
		id: userId,
		name: userName,
		role = 'user',
	} = data;
	return { userId, userName, role };
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'destructuring with rename and default values');
}

# for...of with async/await
{
	my $input = <<'END';
async function processItems(items) {
for (const item of items) {
const result = await processOne(item);
if (result.error) {
console.error(result.error);
}
}
}
END

	my $expected = <<'END';
async function processItems(items) {
	for (const item of items) {
		const result = await processOne(item);
		if (result.error) {
			console.error(result.error);
		}
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'for...of loop with async/await');
}

# Private class fields and static methods
{
	my $input = <<'END';
class Counter {
#count = 0;
static create() {
return new Counter();
}
increment() {
this.#count++;
}
get value() {
return this.#count;
}
}
END

	my $expected = <<'END';
class Counter {
	#count = 0;
	static create() {
		return new Counter();
	}
	increment() {
		this.#count++;
	}
	get value() {
		return this.#count;
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'private class fields and static methods');
}

# Promise.all with async arrow functions
{
	my $input = <<'END';
async function fetchAll(ids) {
const results = await Promise.all(
ids.map(async (id) => {
const res = await fetch(`/api/${id}`);
return res.json();
})
);
return results;
}
END

	my $expected = <<'END';
async function fetchAll(ids) {
	const results = await Promise.all(
		ids.map(async (id) => {
				const res = await fetch(`/api/${id}`);
				return res.json();
			})
	);
	return results;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'Promise.all with nested async arrow functions');
}

done_testing();
