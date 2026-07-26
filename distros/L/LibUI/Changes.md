# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.0] - 2026-07-25

This is the first version with all of libui-ng's full widget set.

### Added

- New examples in `eg/`:
  - `timer.pl` - demonstrates `uiTimer` by printing timestamps every second
  - `hello_world.pl` - minimal "Hello, World!" window
  - `controlgallery.pl` - port of the upstream libui-ng control gallery showcasing basic controls, numbers, lists, and data choosers
  - `calculator.pl` - basic calculator with grid layout, menus, and a settings dialog
  - `clock.pl` - animated analog clock using `uiArea`, `uiTimer`, and draw matrix transforms
  - `datetime.pl` - demonstrates `uiDateTimePicker` with date, time, and combined pickers
  - `fontpicker.pl` - demonstrates `uiFontButton` and reading font properties
  - `form.pl` - demonstrates `uiForm` layout with various control types
  - `graph.pl` - plots mathematical functions from editable spinbox data points
  - `grid.pl` - demonstrates `uiNewGrid` with cell spanning and stretchy controls
  - `group.pl` - demonstrates `uiNewGroup`, `uiGroupSetMargined`, and dynamic group titles
  - `image.pl` - demonstrates `uiNewImage` and image columns in a table
  - `matrix.pl` - animated `uiDrawMatrix` transforms (translate, scale, rotate, skew)
  - `menu.pl` - demonstrates all menu types: items, check items, separators, enable/disable, and submenus
  - `notepad.pl` - multi-document tabbed text editor with file open/save and dirty tracking
  - `quiz.pl` - interactive multiple-choice quiz with navigation, scoring, and results review
  - `scrollarea.pl` - demonstrates `uiNewScrollingArea` with a large interactive map
  - `separators.pl` - demonstrates `uiNewHorizontalSeparator` and `uiNewVerticalSeparator`
  - `stopwatch.pl` - start/stop/lap timer using `uiTimer` and `Time::HiRes`
  - `tab.pl` - demonstrates `uiTab` with append, insert, delete, margined, and selection tracking
  - `table.pl` - demonstrates `uiNewTableModel` with sortable columns
  - `text_attributes.pl` - demonstrates `uiAttributedString` with styled text rendering
  - `bittorrent_threads.pl` - multi-threaded BitTorrent client using ithreads for background networking

### Changed

- `uiNewArea` and `uiNewScrollingArea` wrap callbacks (`Draw`, `MouseEvent`, `KeyEvent`). to tansparently handle casting opaque pointers to useful structs.

## [0.02] - 2023-03-11

### Added

- New widgets:
    - `LibUI::Area` (very rough)
    - `LibUI::ScrollingArea`
- New example scripts:
    - `eg/demo.pl`: very basic, "Hello, World!" type of example
    - `eg/widgets.pl`: demo of (nearly all) basic controls
    - `eg/histogram.pl`: demo of `LibUI::Area` and related functions
- New enum and structs: `LibUI::Area::Handler`, `::KeyEvent`, `::MouseEvent`, `::Modifiers`

### Changed

- Renamed widgets to fit existing pattern:
    - `LibUI::HorizontalSeparator` => `LibUI::HSeparator`
    - `LibUI::VerticalSeparator` => `LibUI::VSeparator`

## [0.01] - 2022-12-07

### Added

- Original version

[Unreleased]: https://github.com/sanko/LibUI.pm/compare/v1.0.0...HEAD
[v1.0.0]: https://github.com/sanko/LibUI.pm/compare/0.02...v1.0.0
[0.02]: https://github.com/sanko/LibUI.pm/compare/0.01...0.02
[0.01]: https://github.com/sanko/LibUI.pm/releases/tag/0.01
