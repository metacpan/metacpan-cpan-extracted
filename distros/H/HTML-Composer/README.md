# HTML::Composer

Compose HTML using Perl data.

## Synopsis

HTML::Composer is inspired by TyXML and Hiccup to provide a data-driven HTML builder for Perl that allows
developers to compose data to validated HTML in an efficient, intuitive, high-performance way.

```perl
  use HTML::Composer;
  
  my $h = HTML::Composer->new();
  my $html = $h->html([
          head => [
              title  => ["My Site"],
              script => {
                  src  => "/js/myScript.js",
                  type => "text/javascript"
              }
          ],
          body => [
              h1  => ["Hello World!"],
              br  => {},
              div => { class => [ "p-3", "background-red" ] } => [
                  "Hello World!", h2 => ["Test 123"]
              ]
          ]
      ]
  );
```

This will output the following HTML:

```html
  <!DOCTYPE html>
  <html>
    <head>
      <title>My Site</title>
      <script src="/js/myScript.js" type="text/javascript"></script>
    </head>
    <body>
      <h1>Hello World</h1>
      <br>
      <div class="p-3 background-red">
        Hello World!
        <h2>Test 123</h2>
      </div>
    </body>
  </html>
```

HTML elements that allow children are created like:

```perl
  [div => ["Text!", h1 => ["Text!"]]] # <div>Text!<h1>Text!</h1></div>
```

To provide attributes to a tag:

```perl
  [div => { class => ["p-3", "m-2"] } => ["Text!", h1 => ["Text!"]]]
    # <div class="p-3 m-2">Text!<h1>Text!</h1></div>
```

If a tag doesn't have any children, ie a &lt;link&gt; tag:

```perl
  [link => { href => "www.google.com" }] # <link href="www.google.com">
```

If a tag doesn't have any attributes:

```perl
  [br => {}] # <br>
```

To render just text, make sure it isn't followed up by an array, or hash:

```perl
  ["Text!"]
```

## HTML::Composer->new(%ARGS)

Create a new instance of HTML::Composer. Optionally, pass a cache argument, to tell
HTML::Composer to cache the result against the hash you pass. (Caching defaults to false).
Caching can increase memory usage, and drastically increase efficiency.

```perl
  my $h = HTML::Composer->new(); # Cached instance of HTML::Composer
  $h->html(...);

  my $hc = HTML::Composer->new(cache => 0); # Don't cache templates
  $hc->html(...);
```

## html(ARRAY)

Create a string containing the HTML described in ARRAY. Croaks if HTML validation fails.

```perl
  my $h = HTML::Composer->new();
  my $html = $h->html([
          head => [
              title  => ["My Site"],
              script => {
                  src  => "/js/myScript.js",
                  type => "text/javascript"
              }
          ],
          body => [
              h1  => ["Hello World!"],
              br  => {},
              div => { class => [ "p-3", "background-red" ] } => [
                  "Hello World!", h2 => ["Test 123"]
              ]
          ]
      ]
  );
```

If you need to pass attributes to the root <html> tag you can do so with:

```perl
  my $h = HTML::Composer->new();
  my $html = $h->html({lang => 'en'} => [
          head => [
              title  => ["My Site"],
              script => {
                  src  => "/js/myScript.js",
                  type => "text/javascript"
              }
          ],
          body => [
              h1  => ["Hello World!"],
              br  => {},
              div => { class => [ "p-3", "background-red" ] } => [
                  "Hello World!", h2 => ["Test 123"]
              ]
          ]
      ]
  );
```

## partial(ARRAY)

Create a string containing an HTML partial described in ARRAY. The array must have a single root element.
Useful for rendering fragments outside of a full page context.

```perl
  my $h = HTML::Composer->new;
  my $html = $h->partial([
    div => [
      "Hello, World!",
      a => { href => "https://www.google.com" } => ["www.google.com"]
    ]
  ]);

  say $html;
  # <div>Hello, World!<a href="https://www.google.com">www.google.com</a></div>
```

## LICENSE

This project is licensed under the MIT license. Please read the `LICENSE` file at the root of the project
for more information.
