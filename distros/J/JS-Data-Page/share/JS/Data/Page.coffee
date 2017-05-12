class Data

class Data.Page
  constructor: (@_total_entries = 0, @_entries_per_page = 10, @_current_page = 1) ->

  total_entries: (total_entries) ->
    @_total_entries = total_entries if total_entries
    return @_total_entries

  entries_per_page: (entries_per_page) ->
    @_entries_per_page = entries_per_page if entries_per_page
    return @_entries_per_page

  current_page: (current_page) ->
    @_current_page = current_page if current_page
    return @_current_page

  first_page: ->
    return 1

  last_page: ->
    pages = @_total_entries / @_entries_per_page
    if pages == Math.floor(pages)
        last_page = pages
    else
        last_page = 1 + Math.floor(pages)
    if last_page < 1
        last_page = 1   
    return last_page

  first: ->
    if @_total_entries == 0
        return 0
    else
        return ( ( @_current_page - 1 ) * @_entries_per_page ) + 1

  last: ->
    if @_current_page == this.last_page()
        return @_total_entries
    else
        return @_current_page * @_entries_per_page

  previous_page: ->
    if @_current_page > 1
        return @_current_page - 1
    else
        return null

  next_page: ->
    if @_current_page < this.last_page()
        return @_current_page + 1
    else
        return null
    
  splice: (array) ->
    if array.length > this.last()
        top = this.last()
    else
        top = array.length
    if top == 0
        return []
    return array.slice(this.first()-1, top)

  skipped: ->
    skipped = this.first() - 1
    if skipped < 0
        return 0
    else
        return skipped

  entries_on_this_page: ->
    if @_total_entries == 0
        return 0
    else
        return this.last() - this.first() + 1

Data.Page.VERSION = "0.02"
