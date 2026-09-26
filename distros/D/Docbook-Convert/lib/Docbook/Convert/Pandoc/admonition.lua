local map = {
  note = "note",
  warning = "warning",
  tip = "tip",
  important = "important",
  caution = "caution",
  danger = "danger"
}

local function drop_title_blocks(content)
  local blocks = pandoc.List()
  for _, block in ipairs(content) do
    if not (block.t == "Div" and block.classes:includes("title")) then
      blocks:insert(block)
    end
  end
  return blocks
end

local function indent(text, spaces)
  local prefix = string.rep(" ", spaces)
  return text:gsub("([^\n]+)", prefix .. "%1")
end

local function admonition_markdown(el, kind)
  local title = el.attributes["title"] or ""
  local heading = "!!! " .. kind
  if title ~= "" then
    heading = heading .. ' "' .. title .. '"'
  end

  local content = pandoc.write(
    pandoc.Pandoc(drop_title_blocks(el.content)),
    "markdown-smart-all_symbols_escapable"
  )
  return heading .. "\n\n" .. indent(content, 4)
end

local function unwrap_example(el)
  if el.classes:includes("example") then
    return drop_title_blocks(el.content)
  end
  return nil
end

local function admonition_div(el)
  local example = unwrap_example(el)
  if example then
    return example
  end

  for class, kind in pairs(map) do
    if el.classes:includes(class) then
      return pandoc.RawBlock("markdown", admonition_markdown(el, kind))
    end
  end
  return nil -- no changes for other Divs
end

return {
  { Div = admonition_div },
}
